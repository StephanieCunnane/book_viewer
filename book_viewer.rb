require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index { |line, idx| "<p id=paragraph#{idx}>#{line}</p>" }.join
  end

  # invokes the block for each chapter, passing that chapter's number, name and
  # contents
  def each_chapter
    @contents.each_with_index do |name, idx|
      number = idx + 1
      contents = File.read "data/chp#{number}.txt"
      yield number, name, contents
    end
  end

  # This method returns an arr of hashes rep chapters that match the specified
  # query. Each hash contains values for its :name, :number and :paragraph keys.
  # The value for :paragraphs will be a hash of paragraph idxs and the
  # corresponding paragraph's text.
  def chapters_matching(query)
    results = []

    return results unless query

    each_chapter do |number, name, contents|
      matches = {}
      contents.split("\n\n").each_with_index do |paragraph, idx|
	matches[idx] = paragraph if paragraph.include?(query)
      end

      results << { number: number, name: name, paragraphs: matches } if matches.any?
    end

    results
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end
end

before do
  @contents = File.readlines 'data/toc.txt'
end

get '/' do
  @title = 'The Adventures of Sherlock Holmes'

  erb :home
end

get '/chapters/:number' do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect '/' unless (1..@contents.size).cover?(number)

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read "data/chp#{number}.txt"

  erb :chapter
end

get '/search' do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect '/'
end
