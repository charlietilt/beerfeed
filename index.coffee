express = require 'express'
app = express()
request = require 'request'
rss = require 'rss'
cheerio = require 'cheerio'

getFeed = (callback) ->
  request.get 'http://thestoutbrothers.com/locations/smyrna/beers-on-tap/', (error, res, html) ->
    return callback error if error?
    $ = cheerio.load html
    beers = $('.beer-box').map (__, el) ->
      title: $(el).find('td:nth-child(3) h5').text()
      abv: $(el).find('h5:contains(ABV)').next('p').text()
      ibu: $(el).find('h5:contains(IBU)').next('p').text()
      image: $(el).find('img').first().attr('src')
      description: $(el).find('td:nth-child(3) h5').next('p').text()
      parings: $(el).find('h5:contains(Food Pairings)').next('p').text()
    .get()
    callback null, beers

app.get '/sbm', (req, res) ->
  getFeed (error, feed) ->
    return res.json 400, 'error getting feed' if error?
    res.json 200, feed

app.listen process.env.PORT or 9000
