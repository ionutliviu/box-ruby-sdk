require 'box/item'

module Box
  class Discussion < Item
    def update(params)
      response = @api.update_discussion(id, params)
      Box::Discussion.new(@api, response.parsed_response)
    end

    def delete
      response = @api.delete_discussion(id)
      Box::Discussion.new(@api, response.parsed_response)
    end

    def add_comment(message)
      response = @api.add_discussion_comment(id, message)
      Box::Comment.new(@api, response.parsed_response)
    end

    def comments
      response = @api.get_discussion_comments(id)
      response['comments'].collect do |comment|
        Box::Comment.new(@api, response.parsed_response)
      end
    end

    protected
    def get_info
      response = @api.get_discussion
      response.parsed_response
    end
  end
end
