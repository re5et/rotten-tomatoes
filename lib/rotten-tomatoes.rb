# A scraper to search for and fetch useful information
# about movies from rottentomatoes.com
#
# Author:: atom smith (http://twitter.com/re5et)
# Copyright:: Copyright (c) 2010 atom smith
# License:: Distributes under the same terms as Ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

# Module to hold everything
module Rotten_tomatoes

  Base_url = 'http://www.rottentomatoes.com'
  Search_url = Base_url + '/search/movie.php?searchby=movies&page=1&search='

  # Create a new instance of Rotten_tomatoes::Movie with the
  # rottentomatoes.com movie path as an argument
  def self.get_info info_path
    Movie.new info_path
  end

  # Search rottentomatoes.com for the movie you are looking for
  # will return an array of movies for you to select from, each
  # will contain the 'info_url' you need to us Rotten_tomatoes:get_info
  def self.find_movie movie
    movies = []
    url = URI.parse(URI.encode(Search_url + movie))
    results = Nokogiri::HTML(open(url))
    results.css('#movie_search_main tr').each do |row|
      movies.push({
                    :title => row.css('td:nth-of-type(3) p:first-of-type a').inner_text,
                    :plot => row.css('td:nth-of-type(3) p:nth-of-type(2)').inner_text.gsub(/\APlot:/, '').strip,
                    :year => row.css('.date').inner_text,
                    :director => row.css('td:nth-of-type(3) p:nth-of-type(3) a:first-of-type').inner_text,
                    :info_url => row.css('td:nth-of-type(3) p:first-of-type a').attr('href').value
                  })
    end
    return movies
  end

  # Uses Rotten_tomatoes::get_info to fetch info for the first
  # search result found with Rotten_tomatoes::find_movie
  def self.lucky_get_info movie
    get_info find_movie(movie).first[:info_url]
  end

  # Rotten_tomatoes::Movie is a class that organizes the scraped
  # information about the movie into easily accessible attribues.
  class Movie

    attr_reader :info_page, :title, :year, :people, :cast, :writers, :directors, :runtime, :rating, :tomatometer, :tomatometer_average_rating, :tomatometer_reviews_counted, :tomatometer_fresh, :tomatometer_rotten, :audience_rating, :audience_average_rating, :audience_number_of_ratings, :genres, :release, :distributor

    def initialize movie_url
      @info_page = Nokogiri::HTML(open(URI.parse(Rotten_tomatoes::Base_url + movie_url)))
      if @info_page
        set_title_and_year
        set_cast
        set_writers
        set_directors
        set_people
        set_runtime
        set_rating
        set_tomatometer
        set_tomatometer_average_rating
        set_tomatometer_reviews_counted
        set_tomatometer_fresh_and_rotten
        set_audience_rating
        set_audience_average_rating
        set_audience_number_of_ratings
        set_genres
        set_release
        set_distributor
      end
      return self
    end

    private

    def set_title_and_year
      title_and_year = @info_page.css('h1.movie_title span').first.inner_html
      match = title_and_year.match(/(.*)\((\d{4})\)/)
      @title = match[1].strip
      @year = match[2]
    end

    def set_cast
      @cast = []
      @info_page.css('#cast-info li').each do |person|
        @cast.push({
                     :name => person.css('a').inner_html,
                     :info_path => person.css('a').first['href'],
                     :thumbnail => person.css('img').first['src'],
                     :characters => person.css('.characters').first.text.gsub('(', '').gsub(')', '')
                   })
      end
    end

    def set_writers
      @writers = []
      @info_page.css('.movie_info .right_col p:nth-child(3) a').each do |writer|
        @writers.push({
                        :name => writer.inner_html,
                        :info_path => writer['href']
                      })
      end
    end

    def set_directors
      @directors = []
      @info_page.css('.movie_info .right_col p:nth-child(2) a').each do |director|
        @directors.push({
                          :name => director.inner_html,
                          :info_path => director['href']
                        })
      end
    end

    def set_people
      @people = { :cast => @cast, :writers => @writers, :directors => @directors }
    end

    def set_runtime
      @runtime = @info_page.css('.movie_info .left_col p:nth-child(2) .content').first.inner_html
    end

    def set_rating
      @rating = @info_page.css('.movie_info .left_col p:first-child .content span').text
    end

    def set_tomatometer
      @tomatometer = @info_page.css('#all-critics-numbers #all-critics-meter').inner_html
    end

    def set_tomatometer_average_rating
      @tomatometer_average_rating = @info_page.css('.critic_stats span:first-of-type').text.gsub(/\/.*/, '')
    end

    def set_tomatometer_reviews_counted
      @tomatometer_reviews_counted = @info_page.css('.critic_stats span:nth-of-type(2)').text
    end

    def set_tomatometer_fresh_and_rotten
      matches = @info_page.css('#all-critics-numbers .critic_stats').text.scan /Fresh:\s(\d+)\s|\sRotten:\s(\d)+/
      @tomatometer_fresh = matches[0][0]
      @tomatometer_rotten = matches[1][1]
    end

    def set_audience_rating
      @audience_rating = @info_page.css('.fan_side .meter').text
    end

    def set_audience_average_rating
      match = @info_page.css('.fan_side .critic_stats').text.match(/Average Rating: ([\d\.]+)\//)
      @audience_average_rating = match[1]
    end

    def set_audience_number_of_ratings
      match = @info_page.css('.fan_side .critic_stats').text.match(/User Ratings: (\d+)/)
      @audience_number_of_ratings = match[1]
    end

    def set_genres
      @genres = []
      @info_page.css('.movie_info p:first-of-type .content a').each do |genre|
        @genres.push genre.text
      end
    end

    def set_release
      @release = info_page.css('.movie_info .left_col p:nth-of-type(3) .content span').text
    end

    def set_distributor
      @distributor = @info_page.css('.movie_info .right_col p:nth-of-type(1)').text.gsub('Distributor:', '')
    end

    public

    def director
      @directors.first
    end

    def writer
      @writers.first
    end

  end

end
