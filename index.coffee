_ = require 'lodash'
express = require 'express'
app = express()
request = require 'request'
Rss = require 'rss'
cheerio = require 'cheerio'
cache = { }

cacheFeed = (data) ->
  cache = { }
  cache.timestamp = Date.now() + 300000
  cache.data = data
  data

getCachedFeed = ->
  return cache.data if cache.data? and cache?.timestamp? and (cache?.timestamp > Date.now())
  null

getFeed = (callback) ->
  feed = getCachedFeed()
  return callback null, feed if feed?
  console.log 'go get the feed...'
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
    feed = cacheFeed(createFeed(beers))
    callback null, feed

createFeed = (data) ->
  feed = new Rss
    title: 'Smyrna Beer Market Beer List'
    description: 'Beers On Tap'
    feed_url: 'http://beerfeed.herokuapp.com/sbm'
    custom_elements: [
      ibv: 'Alcohol By Volume'
    ,
      ibu: 'International Bitterness Units'
    ,
      thumbnail: 'Beer thumbnail'
    ]

  data.forEach (beer) ->
    feed.item
      title: beer.title
      url: 'http://thestoutbrothers.com/locations/smyrna/beers-on-tap/'
      description: beer.description
      date: new Date()
      guid: "http://thestoutbrothers.com/locations/smyrna/beers-on-tap/##{beer.title}"
      custom_elements: [
        ibv: beer.ibv
      ,
        ibu: beer.ibu
      ,
        thumbnail: beer.image
      ]
  feed

app.get '/sbm', (req, res) ->
  getFeed (error, feed) ->
    return res.json 400, 'error getting feed' if error?
    res.set 'Content-Type', 'text/xml'
    res.status(200).send feed.xml()

app.listen process.env.PORT or 9000
