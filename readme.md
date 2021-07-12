# [Inews Poll Tracker](https://inews.co.uk/news/politics/uk-poll-tracker-latest-opinion-polls-major-political-parties-explained-1091547)

### This is the back-end and front-end code for the Inews Poll Tracker

The tracker collects nationwide voter intention polls which are released by members of the British polling council.

Our model dynamically weights those polls by the dates they were in the field, surveying people so the most recent polls count for a lot more than the earliest ones. It also considers which polling organisation carried out the poll, as each polling organisation has a slightly different method of constructing polls.

Our tracker also provides a 95 per cent confidence interval, so that readers can see not just the topline estimates, but also the range of values within which we believe the true level of support for each party lies.

The tracker itself is based on a tracker designed by [Jack Bailey](https://github.com/jackobailey/poll_tracker).


### Files
* scrape.py
  * Scraping polls from Wikipedia
* mainviz.R
  * Modelling the data and visualising it.
* _outout/
  * Model output
