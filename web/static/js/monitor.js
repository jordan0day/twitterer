import {Socket} from "phoenix"

export function monitor_hashtag(hashtag, user_info) {
  console.log("in monitor_hashtag for " + hashtag);
  console.log("user_info: " + JSON.stringify(user_info));
  let socket = new Socket("/monitor/ws");
  socket.connect();
  let chan = socket.chan("monitor:" + hashtag, user_info);
  chan.join().receive("ok", () => {
    console.log("Monitoring!");
    console.log("chan: " + chan);
  });
  chan.onError(e => console.log("something went wrong: " + JSON.stringify(e)));
  chan.onClose(e => console.log("channel closed: " + JSON.stringify(e)));
};

console.log("monitor.js loaded!");