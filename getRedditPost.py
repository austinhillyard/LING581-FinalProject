# DistilBert, use cls token to delinieate things.

import praw
import pandas as pd
import datetime as dt
import json

# data = None

# with open("keys.json", "r") as keys:
#     data=keys.read()

# keys_obj = json.loads(data)

reddit = praw.Reddit(client_id= 'Redacted',  # your app's ID code
                     client_secret='Redacted',  # your app's secret code
                     user_agent= 'Redacted',  # your app's name (e.g., Scraper)
                     username='Redacted',  # your Reddit username
                     password='Redacted')  # your Reddit password



def getComments(comments, limit = 50):
    topcomments = []
    numComments = 0
    for comment in comments:
        if isinstance(comment, praw.models.Comment):
            topcomments.append(comment.body)
            numComments += 1
            if numComments == limit:
                break
    return topcomments
    

# Get x posts given a subreddit, and parses the info into a dictionary.
def getPostsText(post):

    # Check if post is unusually long
    selftext = post.selftext
    title = post.title
    content = "[CLS]" + title + " [SEP] " + selftext + "[SEP] "

    return content


def parseSubreddits(subreddits, numPosts=100, numCommentsPerPost = 50):
    data = {
        "subreddit": [],
        "content": [],
        "type": [],
    }
    
    for subreddit_name in subreddits:
        subreddit = reddit.subreddit(subreddit_name)
        top_posts = subreddit.hot(limit = numPosts)
        for post in top_posts:
            data["subreddit"].append(subreddit.display_name)
            data["content"].append(getPostsText(post))
            data["type"].append("Post")
            for comment in getComments(post.comments, numCommentsPerPost):
                data["subreddit"].append(subreddit.display_name)
                data["content"].append(comment)
                data["type"].append("Comment")
        print("Finished subreddit ", subreddit_name)

    return data

# Get subreddits
subreddits = ["Warhammer40k", "Warhammer", "ageofsigmar", "PrequelMemes"
              , "lotrmemes", "politics", "Conservative", "democrats", "Republican",
                "gaming", "StarWars", "lotr", "retrogaming", "ProgrammerHumor", "CloneWarsMemes",
                "Funnymemes", "minipainting", "SteamDeck", "Steam", "linux", "windows", "Grimdank"]



stuff = parseSubreddits(subreddits, 50, 100)

data = pd.DataFrame(stuff)

data.to_csv("dataTest.csv", encoding="utf-8")