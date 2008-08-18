class Imdb
  IMDB_MOVIE_BASE_URL = "http://www.imdb.com/title/"
  IMDB_NAME_BASE_URL = "http://www.imdb.com/name/"
  IMDB_COMPANY_BASE_URL = "http://www.imdb.com/company/"
  IMDB_GENRE_BASE_URL = "http://www.imdb.com/Sections/Genres/"
  IMDB_SEARCH_BASE_URL = "http://www.imdb.com/find?s=tt&q="

  class << self
    @@movies = {}
    
    private :new

    def find_movie_by_id(id)
      @@movies[id.to_sym] ||= begin
        data = Hpricot(open(IMDB_MOVIE_BASE_URL + id))

        movie = Imdb::Movie.new

        movie.imdb_id = id
        movie.title = data.at("meta[@name='title']")['content'].gsub(/\(\d\d\d\d\)/,'').strip

        rating_text = (data/"div.rating/b").inner_text
        if rating_text =~ /([\d\.]+)\/10/
          movie.rating = $1
        end

        movie.poster_url = data.at("div.photo/a[@name='poster']/img")['src'] rescue nil

        (data/"div.info").each do |info|
          case (info/"h5").inner_text
          when /Directors?:/
            movie.directors = parse_names(info)
          when /Writers?:/
            movie.writers = parse_names(info)
          when /Company:/
            movie.company = parse_company(info)
          when "Tagline:"
            movie.tagline = parse_info(info).strip
          when "Runtime:"
            movie.runtime = parse_info(info).strip
          when "Plot:"
            movie.plot = parse_info(info).gsub(/full summary.*$/,'').strip
          when "Genre:"
            movie.genres = parse_genres(info)
          when "Release Date:"
            begin
              if (parse_info(info).strip =~ /(\d{1,2}) ([a-zA-Z]+) (\d{4})/)
                movie.release_date = Date.parse("#{$2} #{$1}, #{$3}")
              end
            rescue
              movie.release_date = nil
            end
          end
        end 

        movie # return movie
      rescue
        nil
      end
    end

    def find_movie_by_name(name)
      # Two cases....
      # One: takes user directly to movie page, in which case get id and call find_movie_by_id
      #     e.g. "Grindhouse planet terror"
      # Two: results page. Ignore for now (this needs to be very intelligent)

      uri = URI(IMDB_SEARCH_BASE_URL + CGI.escape(name))
      result = uri.open

      
      if result.base_uri == uri
        contents = result.read.to_s
        if id = contents.scan(/\(Exact Matches\).*?\/title\/(tt\d+)/)
          find_movie_by_id( id[0].to_s )
        else
          nil
        end
      else # We've been redirected straight to movie page
        id = result.base_uri.to_s.gsub(/.*\/(tt\d+)(\/.*?)?/) { |m| m[0] }
        find_movie_by_id(id)
      end
    end

    protected

    def parse_info(info)
      value = info.inner_text.gsub(/\n/,'') 
      if value =~ /\:(.+)/ 
        value = $1
      end
      value.gsub(/ more$/, '')
    end

    def parse_names(info)
      # <a href="/name/nm0083348/">Brad Bird</a><br/><a href="/name/nm0684342/">Jan Pinkava</a> (co-director)<br/>N
      info.inner_html.scan(/<a href="\/name\/([^"]+)\/">([^<]+)<\/a>( \(([^)]+)\))?/).map do |match|
        Imdb::Name.new(match[0], match[1], match[3])
      end
    end

    def parse_company(info)
      # <a href="/company/co0017902/">Pixar Animation Studios</a>
      match = info.inner_html =~ /<a href="\/company\/([^"]+)\/">([^<]+)<\/a>/;
      Imdb::Company.new($1, $2)
    end

    def parse_genres(info)
      # <a href="/Sections/Genres/Animation/">Animation</a> / <a href="/Sections/Genres/Adventure/">Adventure</a>
      genre_links = (info/"a").find_all do |link|
        link['href'] =~ /^\/Sections\/Genres/
      end 
      genre_links.map do |link|
        genre = link['href'] =~ /([^\/]+)\/$/
        Imdb::Genre.new($1, $1)
      end
    end
  end
end
