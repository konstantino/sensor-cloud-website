class SearchesController < ApplicationController

  def show
  end

	def create
		if params['search']['query'].blank?
			redirect_to root_path
		else
      conn = Faraday.new(:url => "#{CONF['API_URL']}") do |faraday|
      	faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      res = conn.post do |req|
        req.url '/_search'
        req.headers['Content-Type'] = 'application/json'

        if params['search']['sort_by'].nil? 
          sort_by = '{}' 
        else 
          sort_by = '{"' + params['search']['sort_by'] + '":"asc" }'
        end
       
        #req.body = '{"query" : {"query_string" : { "query" : "' + params['search']['query'] + '"}}}'
		  if params['search']['filter'].nil?
      req.body = '{ "sort": ['+ sort_by + '],
                    "query" : {"query_string" : { "query" : "' + params['search']['query'] + '"}}
                    }'
      else
      req.body = '{ "sort": ['+ sort_by + '],
                  "query": {
                    "filtered": {
                      "query" : {"query_string" : { "query" : "' + params['search']['query'] + '"}},
                      "filter":{
                        "or":[{        
                        "regexp":{ "name" : { "value" : ".*' + params['search']['filter'] + '.*"}}                   
                          },{
                        "regexp":{ "tags" : { "value" : ".*' + params['search']['filter'] + '.*"}}                   
                        }]
                      }
                    }
                  }
                }'
      end
        	logger.debug "#{req.body}"

      end
			logger.debug "#{res.body}"
      json = JSON.parse(res.body)
      @streams = json['streams']['hits']['hits']
      @users = json['users']['hits']['hits']
      @count_streams = json['streams']['hits']['total']
      @count_users = json['users']['hits']['total']
      @count_all = json['streams']['hits']['total'] + json['users']['hits']['total']
			@query = params['search']['query']

			render :action => 'show'
		end
	end
end
