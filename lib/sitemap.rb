#
# = sitemap.rb - Sitemap
#
# Author:: Daniel Mircea daniel@viseztrance.com
# Copyright:: Copyright (c) 2011 Daniel Mircea, The Geeks
# License:: MIT and/or Creative Commons Attribution-ShareAlike

require "singleton"
require "builder"
require "sitemap/railtie"

module Sitemap

  class Generator

    include Singleton

    VERSION = Gem::Specification.load(File.expand_path("../sitemap.gemspec", File.dirname(__FILE__))).version.to_s
    SEARCH_ATTRIBUTES = {
      :change_frequency => "changefreq",
      :priority         => "priority"
    }

    attr_accessor :entries, :host

    def initialize
      self.class.send(:include, Rails.application.routes.url_helpers)
      self.entries = []
    end

    def render(options = {}, &block)
      options.each do |k, v|
        self.send("#{k}=", v)
      end
      instance_exec(self, &block)
    end

    def path(object, options = {})
      params = options[:params] ? options[:params].clone : {}
      params[:host] = params[:host].respond_to?(:call) ? params[:host].call(object) : host

      search = options.select { |k, v| SEARCH_ATTRIBUTES.keys.include?(k) }

      self.entries << {
        :object => object,
        :search => search,
        :params => params
      }
    end

    def collection(type, options = {})
      objects = options[:objects] ? options[:objects].call : type.to_s.classify.constantize.all
      options.reject! { |k, v| k == :objects }

      objects.each do |object|
        path(object, options)
      end
    end

    def build
      xml = Builder::XmlMarkup.new(:indent => 2)
      file = File.read(File.expand_path("../views/index.xml.builder", __FILE__))
      instance_eval file
    end

    def save(location)
      file = File.new(location, "w")
      file.write(build)
      file.close
    end

  end

end
