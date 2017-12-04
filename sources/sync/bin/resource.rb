#!/usr/bin/ruby -d

require 'pp'
require 'logger'
require 'optparse'
require 'json'
require 'ostruct'
require 'fileutils'
require 'apipie-bindings'

class ConfigureAndSetup

  @@bin_part = '/bin'
  @@etc_part = '/etc'
  @@var_part = '/var'
  @@log_part = '/log'
  @@tmp_part = '/tmp'
  @@config_file_name = 'resource_config.json'

  attr_accessor :model, :environment, :config, :options, :parser, :logger, :script_path, :script_name, :base_dir, :etc_dir, :bin_dir, :var_dir, :log_dir, :tmp_dir, :file_name, :file_path, :api_uri
  attr_reader :environment_name, :action_name, :resource_name, :resource_collection_name, :resource_id, :parent_resource_name, :parent_resource_collection_name, :parent_resource_id

  def initialize
    if $0.start_with? '/'
      @script_path = $0
    else
      @script_path = Dir.pwd + $0.sub(/\./, '')
    end

    @script_name = get_base_name(@script_path )
    @base_dir = get_base_dir(@script_path )

    @etc_dir = @base_dir + @@etc_part
    @bin_dir = @base_dir + @@bin_part
    @var_dir = @base_dir + @@var_part
    @log_dir = @base_dir + @@log_part
    @tmp_dir = @base_dir + @@tmp_part

    parse_command_line_options()
    parse_configuration()
    setup_options()
    setup_environment()

    @logger = Logger.new(STDERR)
    @logger.level = config.log_level

    @api_uri = "https://#{@environment.host_name}.#{@environment.host_domain}#{@environment.web_context}"
  end

  def get_base_dir path
    base_path = File.dirname path
    return base_path.sub /#{@@bin_part}/,  ''
  end

  def get_base_name path
    return File.basename path
  end

  def parse_configuration
    config_json = File.read("#{@etc_dir}/#{@@config_file_name}")
    @config = JSON.parse(config_json, object_class: OpenStruct)
  end

  def parse_command_line_options
    @options = {}

    @parser = OptionParser.new do |option|
      option.banner = "Usage: #{@script_name} [options]"
      option.on('-e', '--environment-name ENV', 'Environement Name') do |environment_name|
        @options[:environment_name] = environment_name
      end
      option.on('-a', '--action-name ACT', 'Action Name') do |action_name|
        @options[:action_name] = action_name
      end
      option.on('-r', '--resource-name NAM', 'Resource Name') do |resource_name|
        @options[:resource_name] = resource_name
      end
      option.on('-i', '--resource-id IDX', 'Resource Id') do |resource_id|
        @options[:resource_id] = resource_id
      end
      option.on('-p', '--parent-resource-name NAM', 'Parent Resource Name') do |parent_resource_name|
        @options[:parent_resource_name] = parent_resource_name
      end
      option.on('-x', '--parent-resource-id IDX', 'Parent Resource Id') do |parent_resource_id|
        @options[:parent_resource_id] = parent_resource_id
      end
      @options[:file_name] = false
      option.on('-f', '--file-name [FIL]', 'File Name') do |file_name|
        @options[:file_name] = file_name || true
      end
      option.on("-h", "--help", "Display this help") do
        hidden_switch = "--argument"
        #Typecast opts to a string, split into an array of lines, delete the line
        #if it contains the argument, and then rejoins them into a string
        puts option.to_s.split("\n").delete_if { |line| line =~ /#{hidden_switch}/ }.join("\n")
        exit
      end
    end

    @parser.parse!
  end

  def setup_options
    if @options[:environment_name] && @options[:action_name] && @options[:resource_name]
      if @options[:environment_name]
        @environment_name = @options[:environment_name]
      end
      if @options[:action_name]
        @action_name = @options[:action_name]
      end
      if @options[:resource_name]
        @resource_name = @options[:resource_name]
        @resource_collection_name = "#{@resource_name}s"
      end
      if @options[:resource_id]
        @resource_id = @options[:resource_id]
      end
      if @options[:parent_resource_name]
        @parent_resource_name = @options[:parent_resource_name]
        @parent_resource_collection_name = "#{@parent_resource_name}s"
      end
      if @options[:parent_resource_id]
        @parent_resource_id = @options[:parent_resource_id]
      end
      @file_path = "#{@var_dir}"
      if @options[:file_name].is_a?String
        @file_name = @options[:file_name]
      elsif @options[:file_name] == true
        @file_name = "#{@action_name}-#{@resource_name}.json"
      end
    else
      puts @parser.help()
      exit
    end
  end

  def setup_environment
    @environment = config.environments[@environment_name]
  end

  def unmap_filter results

  end

  def map_filter results
    osresults = []
    osresult = {}

    input = {}

    @logger.debug("map_filter: results: #{results}")
    attributes = @config.map.attributes
    resource_collections = @config.map.resource_collections
    @logger.debug("map_filter: resource_collection_name: #{@resource_collection_name}")
    resource_collection = resource_collections[eval(":#{@resource_collection_name}")]
    if resource_collection
      resource_collection_attributes = OpenStruct.new()
      if resource_collection["attributes"]
        resource_collection_attributes = resource_collection.attributes
        mapped_attributes = resource_collection_attributes.marshal_dump.merge(attributes.marshal_dump)
      else
        resource_collection.attributes = attributes
        resource_collection_attributes = resource_collection.attributes
        mapped_attributes = resource_collection_attributes.marshal_dump
      end
    else
      resource_collection = OpenStruct.new()
      resource_collection.attributes = attributes
      resource_collection_attributes = resource_collection.attributes
      mapped_attributes = resource_collection_attributes.marshal_dump
    end
    @logger.debug("map_filter: mapped_attributes: #{mapped_attributes}")

    if results != nil
      @logger.debug "map_filter: result is not null and a #{results.class.inspect}"
      if results.is_a?(Hash)
        input = [results]
        @logger.debug "map_filter: input #{input.inspect}"
      else
        input = results
        @logger.debug "map_filter: input #{input.inspect}"
      end
      input.each do |entry|
        @logger.debug "map_filter: result entry #{entry.inspect}"
        osresult = OpenStruct.new
        entry.each do |name, value|
          @logger.debug "map_filter: entry name: #{name} value: #{value}"
          if mapped_attributes.has_key?(eval(":#{name}"))
            attribute_action = mapped_attributes[eval(":#{name}")]
            @logger.debug "map_filter: attribute #{name} action #{attribute_action}"
            case attribute_action
              when /^(copy.*)$/
                @logger.debug "map_filter: $1 attribute #{name} = #{value}"
                osresult[name] = value
              when /^(rename):(.*)/
                @logger.debug "map_filter: $1 attribute from #{name} to #{$2} = #{value}"
                osresult[$2] = value
            end
            @logger.debug "map_filter: mapping attribute #{name} and setting its value to #{value}"
          end
        end
        osresults << osresult.to_h
      end
    else
      logger.warn("map_filter: results where empty - abort.")
    end
    return osresults
  end

  def get_json_from_file
    json = {}
    if @options[:file_name].is_a?String || @options[:file_name] == true
      file = File.new("#{@file_path}/#{@file_name}", "r")
      begin
        data = file.read()
        json = JSON.parse!(data)
      rescue StandardError => error
        logger.error error
      ensure
        file.close()
      end
    end
    return json
  end

end

result = {}
setup = ConfigureAndSetup.new
logger = setup.logger
options = setup.options
config = setup.config
environment = setup.environment

logger.info("minimum configuration options meet- continue")
if environment != nil
  logger.info("environment configuration exists and environment name #{setup.environment_name} matched configured environment - continue")

  resources = config.map.resource_collections.marshal_dump

  logger.info("environment_name: #{setup.environment_name}")
  logger.info("action_name: #{setup.action_name}")
  logger.info("resource_name: #{setup.resource_name}")
  logger.info("resource_collection_name: #{setup.resource_collection_name}")
  logger.info("resource_id: #{setup.resource_id}")
  logger.info("parent_resource_name: #{setup.parent_resource_name}")
  logger.info("parent_resource_collection_name: #{setup.parent_resource_collection_name}")
  logger.info("parent_resource_id: #{setup.parent_resource_id}")

  api = ApipieBindings::API.new({:uri => setup.api_uri, :username => environment.api_username, :password => environment.api_password, :api_version => environment.api_version}, {:verify_ssl => environment.api_verify_ssl})

  parent_resource_id_name = ":#{setup.parent_resource_name}_id"
  logger.info("parent resource id name: #{parent_resource_id_name}")

  resource_collection = api.resource(eval(":#{setup.resource_collection_name}"))
  action = resource_collection.action(eval(":#{setup.action_name}"))

  case setup.action_name
  when "index"
    logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name} from api uri #{setup.api_uri} ..."
    logger.debug "main: result before action: #{result.inspect}"
    if options[:parent_resource_id]
      result = action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :per_page=>9999)
    else
      result = action.call(:per_page=>9999)
    end
    logger.debug "main: result after action: #{result.inspect}"
    result = setup.map_filter(result["results"])
  when "show"
    logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name}/#{setup.resource_id} from api uri #{setup.api_uri} ..."
    logger.debug "main: result before action: #{result.inspect}"
    if options[:parent_resource_id]
      result = action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>setup.resource_id)
    else
      result = action.call(:id=>setup.resource_id)
    end
    logger.debug "main: result after action: #{result.inspect}"
    result = setup.map_filter(result)
  when "create"
    logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name} from api uri #{setup.api_uri} ..."
    setup.get_json_from_file.each do |entry|
      if options[:parent_resource_id]
        logger.info "create new resource parent_resource_id_name: #{parent_resource_id_name} with entry: #{entry}"
        action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, eval(":#{setup.resource_name}")=>entry)
      else
        logger.info "create new resource: #{setup.resource_name} with entry: #{entry}"
        action.call(eval(":#{setup.resource_name}")=>entry)
      end
    end
  when "update"
    logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name} from api uri #{setup.api_uri} ..."
    setup.get_json_from_file.each do |entry|
      resource_id = resource_collection.action(:show).call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>entry["name"])["id"]
      logger.info "resource_id: #{resource_id}"
      if options[:parent_resource_id]
        logger.info "update resource: #{parent_resource_id_name} = #{setup.parent_resource_id} and id #{resource_id} and :#{setup.resource_name} = #{entry}"
        action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>resource_id, eval(":#{setup.resource_name}")=>entry)
      else
        logger.info "update resource: #{setup.resource_name} = #{entry}"
        action.call(:id=>resource_id, eval(":#{setup.resource_name}")=>entry)
      end
    end
  when "destroy"
    setup.get_json_from_file.each do |entry|
      begin
        logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name}/#{entry["name"]} from api uri #{setup.api_uri} ..."
        if options[:parent_resource_id]
          logger.info action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>entry["name"])
        else
          logger.info action.call(:id=>entry["name"])
        end
      rescue StandardError => error
        logger.error "errror: #{error}"
      end
    end
  else
    logger.error "unknown action #{action_name} - valid actions are index, show, create, update, destroy"
  end

  if result != nil && result.include?("results")
    result = setup.map_filter(result["results"])
  end
  logger.debug "main: result after map_filter: #{result.inspect}"

  logger.info("prepare the write of the result to file #{setup.file_path}/#{setup.file_name}")
  if setup.file_path && !(options[:action_name] == "create") && !(options[:action_name] == "update") && !(options[:action_name] == "destroy")
    logger.info("writing result to file #{setup.var_dir}/#{setup.file_name}")
    file = File.new("#{setup.file_path}/#{setup.file_name}", "w")
    begin
      file.write(result.to_json)
    rescue StandardError => error
      logger.error(error)
    ensure
      file.close
    end
  end
  logger.info(result.to_json)
else
  logger.error "environemnt #{env_name} not found, please check the configuration."
end
