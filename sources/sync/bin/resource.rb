#!/usr/bin/ruby -d

require 'pp'
require 'logger'
require 'optparse'
require 'json'
require 'ostruct'
require 'fileutils'
require 'apipie-bindings'
require 'deep_merge'

class Hash
  def to_o
    JSON.parse to_json, object_class: OpenStruct
  end
end

class ConfigureAndSetup

  @@bin_part = '/bin'
  @@etc_part = '/etc'
  @@var_part = '/var'
  @@log_part = '/log'
  @@tmp_part = '/tmp'
  @@config_file_name = 'resource_config.json'
  @@config_auth_file_name = 'resource_config_auth.json'
  @@log_level = 'info'

  attr_accessor :model, :environment, :config, :options, :parser, :logger, :script_path, :script_name, :base_dir, :etc_dir, :bin_dir, :var_dir, :log_dir, :tmp_dir, :file_name, :file_path, :config_file_name, :config_auth_file_name, :api_uri
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

    @logger = Logger.new(STDERR)
    @logger.level = Logger::DEBUG

    init_options()
    setup_options()
    setup_configuration()
    setup_environment()

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

  def init_options
    @options = {}

    @parser = OptionParser.new do |option|
      option.banner = "Usage: #{@script_name} [options]"
      option.on('-e', '--environment-name ENV', 'Environement Name: ENV') do |environment_name|
        @options[:environment_name] = environment_name
      end
      @options[:action_name] = 'index'
      option.on('-a', '--action-name ACT', "Action Name: [ACT:#{@options[:action_name]}]") do |action_name|
        @options[:action_name] = action_name
      end
      option.on('-r', '--resource-name RES', 'Resource Name: RES') do |resource_name|
        @options[:resource_name] = resource_name
      end
      option.on('-i', '--resource-id RIX', 'Resource Index RIX') do |resource_id|
        @options[:resource_id] = resource_id
      end
      option.on('-p', '--parent-resource-name PAR', 'Parent Resource Name PAR') do |parent_resource_name|
        @options[:parent_resource_name] = parent_resource_name
      end
      option.on('-x', '--parent-resource-id PIX', 'Parent Resource Index PIX') do |parent_resource_id|
        @options[:parent_resource_id] = parent_resource_id
      end
      option.on('-q', '--query_for QRY', 'Query Results using QRY') do |query_for|
        @options[:query_for] = query_for
      end
      option.on('-s', '--sort-and-order-by FLST', 'Sort and Order Results by FLST') do |sort_and_order_by|
        @options[:sort_and_order_by] = sort_and_order_by
      end
      @options[:file_name] = false
      option.on('-f', '--file-name [FIL]', 'Input / Output File Name [FIL]') do |file_name|
        @options[:file_name] = file_name || true
      end
      @options[:config_file_name] = false
      option.on('-c', '--config-file-name [CFIL]', "Config File Name [CFIL:#{@@config_file_name}]") do |config_file_name|
        @options[:config_file_name] = config_file_name || true
      end
      @options[:config_auth_file_name] = false
      option.on('-z', '--config-auth-file-name [AFIL]', "Config Auth File Name [AFIL:#{@@config_auth_file_name}]") do |config_auth_file_name|
        @options[:config_auth_file_name] = config_auth_file_name || true
      end
      @options[:log_level] = false
      option.on('-v', '--log-level [LLVL]', "Log Level (fatal|error|warn|info|debug) [LLVL:#{@@log_level}]") do |config_auth_file_name|
        @options[:config_auth_file_name] = config_auth_file_name || "info"
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
      else
        @file_name = "#{@action_name}-#{@resource_name}.json"
      end
      if @options[:config_file_name].is_a?String
        @config_file_name = @options[:config_file_name]
      else
        @config_file_name = @@config_file_name
      end
      if @options[:config_auth_file_name].is_a?String
        @config_auth_file_name = @options[:config_auth_file_name]
      else
        @config_auth_file_name = @@config_auth_file_name
      end
    else
      puts @parser.help()
      exit
    end
  end

  def setup_configuration
    config_file_path = "#{@etc_dir}/#{@config_file_name}"
    @logger.debug "reading config_file_path: #{config_file_path}"
    config_json = File.read("#{config_file_path}")
    @logger.debug "parsing config_json: #{config_json.inspect}"
    config_os = JSON.parse(config_json, object_class: OpenStruct)
    @logger.debug "constructing config_os: #{config_os.inspect}"

    config_auth_file_path = "#{@etc_dir}/#{@config_auth_file_name}"
    @logger.debug "reading config_auth_file_path: #{config_auth_file_path}"
    config_auth_json = File.read("#{config_auth_file_path}")
    @logger.debug "parsing config_auth_json: #{config_auth_json.inspect}"
    config_auth_os = JSON.parse(config_auth_json, object_class: OpenStruct)
    @logger.debug "constructing config_auth_os: #{config_auth_os.inspect}"

    @logger.debug "environments: #{config_os.environments.inspect}"
    environment = config_os.environments[@environment_name]
    @logger.debug "config_auth_os.api_username: #{config_auth_os.environments[@environment_name].api_username}"
    @logger.debug "config_auth_os.api_password: #{config_auth_os.environments[@environment_name].api_password}"
    environment.api_username = config_auth_os.environments[@environment_name].api_username
    environment.api_password = config_auth_os.environments[@environment_name].api_password
    @logger.debug "environment: #{environment.inspect}"

    @config = OpenStruct.new(config_os)
    @logger.debug "config: #{@config.inspect}"
  end

  def setup_environment
    @logger.info "setup_environment: #{@environment_name} => #{config.environments[@environment_name]}"
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
        osresults << osresult.to_h()
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

  parent_resource_id_name = String.new()
  resource_collection = api.resource(eval(":#{setup.resource_collection_name}"))
  action = resource_collection.action(eval(":#{setup.action_name}"))

  logger.info "lookup route for resource (#{setup.resource_name}) / parent resource (#{setup.parent_resource_name}) association"
  action.routes.each do |route|
    if route.path =~ /^\/api\/#{setup.parent_resource_collection_name}\/(.*)\/#{setup.resource_collection_name}.*$/
      parent_resource_id_name = $1
      logger.info "found route match for resource #{setup.resource_name}: parameter name #{parent_resource_id_name} route #{route.path}"
    end
  end
  logger.info("parent resource id name: #{parent_resource_id_name}")

  case setup.action_name
  when "index"
    logger.debug "main: result before action: #{result.inspect}"
    if options[:parent_resource_id]
      logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name} from api uri #{setup.api_uri} ..."
      result = action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :per_page=>9999)
    else
      logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.resource_collection_name} from api uri #{setup.api_uri} ..."
      result = action.call(:per_page=>9999)
    end
    logger.debug "main: result after action: #{result.inspect}"
    result = setup.map_filter(result["results"])
  when "show"
    logger.debug "main: result before action: #{result.inspect}"
    if options[:parent_resource_id]
      logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name}/#{setup.resource_id} from api uri #{setup.api_uri} ..."
      result = action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>setup.resource_id)
    else
      logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.resource_collection_name}/#{setup.resource_id} from api uri #{setup.api_uri} ..."
      result = action.call(:id=>setup.resource_id)
    end
    logger.debug "main: result after action: #{result.inspect}"
    result = setup.map_filter(result)
  when "create"
    setup.get_json_from_file.each do |entry|
      if options[:parent_resource_id]
        logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.parent_resource_collection_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name}: #{parent_resource_id_name} => #{setup.parent_resource_id}, entry => #{entry} from api uri #{setup.api_uri} ..."
        action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, eval(":#{setup.resource_name}")=>entry)
      else
        logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.resource_collection_name} #{setup.resource_name} => #{entry} from api uri #{setup.api_uri} ..."
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
        if options[:parent_resource_id]
          logger.info "#{setup.environment_name}: #{setup.action_name}@/#{parent_resource_id_name}/#{setup.parent_resource_id}/#{setup.resource_collection_name}: id => #{entry["name"]} from api uri #{setup.api_uri} ..."
          action.call(eval(parent_resource_id_name)=>setup.parent_resource_id, :id=>entry["name"])
        else
          logger.info "#{setup.environment_name}: #{setup.action_name}@/#{setup.resource_collection_name}: id => #{entry["name"]} from api uri #{setup.api_uri} ..."
          action.call(:id=>entry["name"])
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
