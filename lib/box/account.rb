require 'box/api'
require 'box/folder'

module Box
  # Represents an account on Box. In order to use the Box api, the user
  # must first grant the application permission to use their account. This
  # is done using OAuth2, which is performed externally to this library.

  class Account
    # Creates an account object using the given Box api key.
    # You can then {#register} a new account or {#authorize} an
    # existing account.
    #
    # @param [String, Api] api the api key to use for the Box api.
    def initialize(api)
      @api = case
        when api.class == Box::Api; api # use the api object as passed in
        else; Box::Api.new(api) # allows user to pass in a string
      end
    end

    # Authorize the account using the given auth token/ticket, or request
    # permission from the user to let this application use their account.
    #
    # An auth token can be reused from previous authorizations provided the
    # user doesn't log out, and significantly speeds up the process. If the
    # auth token if invalid or not provided, the account tries to log in
    # normally and requires the user to log in and provide access for their
    # account.
    #
    # A ticket can be used for applications that do not block on the user,
    # such as a website, where specifying a redirection url is not possible.
    #
    # In order to maintain backwards compatibility, a ticket can only be
    # specified in the hash syntax, while an auth token can be used in
    # either the hash or string syntax.
    #
    # @param [Optional, String, Hash{:ticket,:auth_token => String}] details
    #        Uses an existing auth token or ticket. If nil, a new ticket
    #        will be generated and used. If a String, it is assumed to be
    #        an auth_token (depreciated). If a Hash, then any values of
    #        the :ticket and :auth_token keys will be used to authenticate.
    # @yield [authorize_url] This block called when the user has not yet
    #        granted this application permission to use their account. You
    #        must have the user navigate to the passed url and authorize
    #        this app before continuing.
    # @return [Boolean] Whether the user is authorized.
    #
    # @example Authorize an account without a saved auth token.
    #   account.authorize do |auth_url|
    #     puts "Please visit #{ auth_url } and enter your account infomation"
    #     puts "Press the enter key once you have done this."
    #     gets # wait for the enter key to be pressed
    #   end
    #
    # @example Authorize an account using an existing auth token.
    #   auth_token = "saved auth token" # load from file ideally
    #   account.authorize(:auth_token => auth_token)
    #
    # @example Combining the above two for the best functionality.
    #   auth_token = "saved auth token" # load from file if possible
    #   account.authorize(:auth_token => auth_token) do |auth_url|
    #     # auth token was invalid or nil, have the user visit auth_url
    #   end
    #
    def authorize(details = nil)
      # for backwards compatibility
      if details.is_a?(Hash)
        auth_token = details[:auth_token]
      else
        auth_token = details
      end

      # use a saved auth token if it is given
      if auth_token
        return true if authorize_token(auth_token)
      end

      # return our authorized status
      authorized?
    end

    # Return the account details. A cached copy will be used if avaliable,
    # and requested if it is not.
    #
    # @param [Boolean] refresh Will not use the cached version if true.
    # @return [Hash] A hash containing all of the user's account
    #         details, or nil if they are not authorized. Please see the
    #         Box api documentation for information about each field.
    #
    # TODO: Add url to Box api documentation, and provide the current fields.
    #
    def info(refresh = false)
      return @info if @info and not refresh

      begin
        cache_info(nil) # reset existing info
        info = @api.get_account_info.to_hash
        cache_info(info)
      rescue Api::NotAuthorized, Api::InvalidInput
        nil
      end
    end

    # Get the root folder of the account. You can use this {Folder} object
    # to access all sub items within the account. This folder is lazy loaded,
    # and a network request will be made if/when the data is requested.
    #
    # @return [Folder] A folder object representing the root folder.
    #
    def root
      return @root if @root
      @root = folder(0)
    end

    # Gets a folder object by id.
    #
    # @param [String] id The id of the folder to fetch.
    #
    # @note This folder will not know its parent because of API
    #       short-comings. If you need the tree above this folder, use
    #       root.find(:type => 'folder', :id => id).first instead.
    #
    # @note This function will return a folder regardless of whether it
    #       actually exists. You will get exceptions if you try to access
    #       any info.
    #
    def folder(id)
      Box::Folder.new(@api, :id => id)
    end

    # Gets a file object by id.
    #
    # @param [String] id The id of the folder to fetch.
    #
    # @note This file will not know its parent because of API
    #       short-comings. If you need the tree above this file, use
    #       root.find(:type => 'file', :id => id).first instead.
    #
    # @note This function will return a file regardless of whether it
    #       actually exists. You will get exceptions if you try to access
    #       any info.
    #
    def file(id)
      Box::File.new(@api, :id => id)
    end

    # @return [Boolean] Is the account authorized?
    def authorized?
      @info != nil
    end

    # Provides an easy way to access this account's info.
    #
    # @example
    #   account.login # returns @info['login']
    def method_missing(sym, *args, &block)
      super unless authorized?

      # TODO: Use symbols instead of strings
      str = sym.to_s

      return @info[str] if @info.key?(str)

      super
    end

    def respond_to?(sym)
      @info.key?(sym.to_s) or super
    end

    protected

    # @return [Api] The api currently in use.
    attr_reader :api

    # Attempt to authorize this account using the given access token. This
    # will only succeed if the auth token has been used before, and
    # be done to make login easier.
    #
    # @param [String] auth_token The auth token to attempt to use
    # @return [Boolean] If the attempt was successful.
    #
    def authorize_token(access_token)
      cache_token(access_token)
      info(true) # force a refresh

      authorized?
    end

    # Use and cache the given auth token.
    # @param [String] auth_token The auth token to cache.
    # @return [String] The auth token.
    def cache_token(access_token)
      @api.set_access_token(access_token)
    end

    # Cache the account info.
    # @param [Hash] info The account info to cache.
    def cache_info(info)
      @info = info
    end
  end
end
