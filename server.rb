require 'sinatra'
require 'pry'
require 'pg'

##############################
####### DB CONNECTION ########
##############################

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

##############################
####### ACTOR METHODS ########
##############################

def get_actors
  sql = "SELECT name, id FROM actors
  ORDER BY name"
  @actors = db_connection do |db|
    db.exec(sql)
  end
  @actors.to_a
end

def find_actor_by_id(id)
  sql = ("SELECT movies.title, actors.name, cast_members.character, movies.id FROM movies
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON cast_members.actor_id = actors.id
  WHERE actors.id = ($1)
  ORDER BY actors.name")

  @actors_id = db_connection do |db|
    db.exec_params(sql, [id])

  end
  @actors_id.to_a
end

##############################
####### MOVIE METHODS ########
##############################

def get_movies
  sql = "SELECT title, id, synopsis
  FROM movies
  ORDER BY title"
  @movies = db_connection do |db|
    db.exec(sql)
  end
  @movies.to_a
end

def page_limit(page_num)
  if page_num.to_i < 1
     offset = 0
      else
      offset = page_num.to_i * 20 - 20
  end
  sql = "SELECT title, id
  FROM movies
  ORDER BY title
  LIMIT 20
  OFFSET $1"

    db_connection do |db|
    db.exec_params(sql, [offset])
  end
end

def find_movie_by_id(id)
  sql = ("SELECT movies.title, movies.year, movies.rating, genres.name AS genre_name, studios.name, actors.name AS actor_name, actors.id AS actor_id
  FROM movies JOIN genres ON movies.genre_id = genres.id
  LEFT JOIN studios ON movies.studio_id = studios.id
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON actors.id = cast_members.actor_id
  WHERE movies.id = ($1)
  ORDER BY title")

  @movies_id = db_connection do |db|
    db.exec_params(sql, [id])
  end
  @movies_id.to_a
end

##############################
########## ROUTES ############
##############################

get '/' do

  erb :index
end

get '/actors' do
  @search_array = []
  @query = params[:query]
  @actors = get_actors
  @actors_search = get_actors { |actor| actor['name']}

  erb :'/actors/index'
end

# * Visiting `/actors/:id` will show the details for a given actor. This
# page should contain a list of movies that the actor has starred in and
# what their role was. Each movie should link to the details page for that movie.

get '/actors/:id' do


  @actor_info = find_actor_by_id(params['id'])


  erb :'/actors/show'
end

# * Visiting `/movies` will show a table of movies, sorted alphabetically
# by title. The table includes the movie title, the year it was released,
# the rating, the genre, and the studio that produced it. Each movie title
# is a link to the details page for that movie.

get '/movies' do
  @search_array = []
  @query = params[:query]
  @movies_search = get_movies { |movie| movie['title']}

  @movies = get_movies

  @page_num = params['page'].to_i || 1
  @movies = page_limit(@page_num)

  erb :'/movies/index'
end

# * Visiting `/movies/:id` will show the details for the movie. This page
#   should contain information about the movie (including genre and studio)
#   as well as a list of all of the actors and their roles. Each actor name
#   is a link to the details page for that actor.

get '/movies/:id' do
  @movie_info = find_movie_by_id(params['id'])

  erb :'/movies/show'
end
