import {Socket} from "phoenix"

var monitored_hashtags = [];
var current_row = "row0";
var user_info = null;
var socket = null;
var hashtag_input = null;
var hashtag_button = null;
var tweets_container = null;

function handle_hashtag_updated(message) {
  console.log("Hashtag " + message["hashtag"] + " updated!");
  let container=$("#tweets-" + message["hashtag"]);

  container.empty();

  message["results"].forEach(function(tweet, index, array) {
    let elem = "<blockquote class='twitter-tweet' id='tweet-" + tweet["id"] + "' data-id='" + tweet["id"] + "'></blockquote>"
    container.append(elem);

    let el = $("#tweet-" + tweet["id"]);
    console.log(el[0]);

    twttr.widgets.createTweet(tweet["id"].toString(), el[0]);

  });
}

function hashtag_button_click() {
  console.log("handling click...");
  let hashtag = hashtag_input.val();
  hashtag.trim();
  if (hashtag.indexOf("#") == 0) {
    hashtag = hashtag.substr(1);
  }
  console.log("new hashtag: " + hashtag);
  watch_hashtag(hashtag);

  hashtag_input.val("");
}

function close_click(hashtag, channel) {
  console.log("close_click: " + hashtag);
  let row = $("#row-" + hashtag);
  console.log("row: " + row);

  var index = monitored_hashtags.indexOf(hashtag);
  monitored_hashtags.splice(index, 1);

  // .leave() closes the channel, and will terminate the server-side channel.
  channel.leave();
  row.remove();
}

function watch_hashtag(hashtag) {
  console.log("hashtag:" + hashtag);
  if(monitored_hashtags.indexOf(hashtag) != -1) {
    console.error("Already watching hashtag " + hashtag);
    return;
  }

  let chan = socket.chan("monitor:" + hashtag, user_info);
  chan.join().receive("ok", () => {
    console.log("Monitoring!");
    console.log("chan: " + chan);
  });
  chan.onError(e => console.log("something went wrong: " + JSON.stringify(e)));
  chan.onClose(e => console.log("channel closed: " + JSON.stringify(e)));
  chan.on("hashtag_updated", handle_hashtag_updated);

  // Set up our visual layout stuff
  monitored_hashtags.push(hashtag);
  let div = "<div class='col-md-12'><div class='panel panel-default'><div class='panel-heading'><h3 class='panel-title'>#" + hashtag + "<button id='close-" + hashtag + "' class='btn btn-sm btn-danger pull-right' style='margin: 0px; padding: 1px;'>Stop watching</button></h3></div><div class='panel panel-body' id='tweets-" + hashtag + "'>Loading...</div></div></div>"
  let row = "<div class='row' id='row-" + hashtag + "'>" + div + "</div>"
  tweets_container.append(row);
  let button = $("#close-" + hashtag);
  button.on("click", () => close_click(hashtag, chan));
}

export function init(hashtag, auth_info) {
  user_info = auth_info;

  console.log("in init for " + hashtag);
  console.log("user_info: " + JSON.stringify(user_info));
  socket = new Socket("/monitor/ws");
  socket.connect();

  hashtag_input = $("#hashtag_input");
  hashtag_button = $("#hashtag_btn");
  hashtag_button.on("click", hashtag_button_click);
  tweets_container = $("#tweets");

  watch_hashtag(hashtag);
};

console.log("monitor.js loaded!");