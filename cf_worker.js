addEventListener("fetch", (event) => {
    event.respondWith(handleRequest(event.request));
  });
  
  async function handleRequest(request) {
    var crosHeaders = {
      "Access-Control-Allow-Origin": "*"
    };
  
    var urlObj = new URL(request.url);
  
    var action = urlObj.searchParams.get("action");
    var actionPath = urlObj.pathname;
  
    var currentDomain = urlObj.hostname;
  
    console.log("CURRENT DOMAIN: " + currentDomain);
  
    var html = `<!DOCTYPE html>
      <html>
  <head>
  <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      <meta name="robots" content="all" />
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>Seedr.CC DOWNLOADER</title>
    <link rel="preconnect" href="https://fonts.gstatic.com">
  <link href="https://fonts.googleapis.com/css2?family=Balsamiq+Sans&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://avipatilpro.github.io/host/z5style.css">
    <link rel="stylesheet" href="https://avipatilpro.github.io/host/zstyle.css">
  <style>
  body{ background-color:#202020;}
  </style>
  </head>
  <body>
    <h1 style="color:orange; text-align:center; cursor: pointer;">THE SEEDR STREAM</h1>
    
  <br><br><h3 style="text-align: center; color: #FFB200; font-family: 'Balsamiq Sans', cursive; font-size: 17px;">👇 Enter Your Magnet URL 👇 <br>And Click On Add..</h3><br><br><br>
    <div><form method="get"  action="/addMagnet" _lpchecked="1">
    <center>
   <div class="bar">
   <input type="search" class="searchbar" name="magnet" value="" placeholder="Enter Magnet Url" autocomplete="off">
  </div>
  <button  class="button" type="submit" value="" title="Stream And Enjoy !!">
  Add Magnet
  </button>
  </form>
  
  <a  class="button" href="/seeAllFiles">
  See All Files
  </a>
  <footer class="footer">
              <div class="container">
                  <span class="copyright"><a style="text-decoration: none; color: #9C9AB3;" href="https://github.com/dgbkn/">© 2021 Dev Goyal</a></span>
              </div>
          </footer>
  </body>
  </html>`;
  
    if (actionPath == "/" && action == null) {
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8"
        }
      });
    }
  
    if (
      actionPath == "/" &&
      action == "addmagnet" &&
      urlObj.searchParams.get("magnet")
    ) {
      await deleteAll();
      var dat = await addMagnet(urlObj.searchParams.get("magnet"));
  
      return new Response(JSON.stringify(dat), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (
      actionPath == "/torrentSearch" &&
      urlObj.searchParams.get("query")
    ) {
      var dat = urlObj.searchParams.get("query");
  
      var details = {
        'query': dat,
        'type': 'search',
      };
  
      var data = await fetch('http://45.61.136.80:8080/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: jsonToformEncoded(details),
      })
  
      return new Response(JSON.stringify(data), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/deleteAll") {
      await deleteAll();
      return new Response(JSON.stringify({ status: "Deleted ALL" }), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/getStatus") {
      var index = urlObj.searchParams.get("index")
        ? urlObj.searchParams.get("index")
        : 0;
  
      var st = await getStatusofTorrent(index);
  
      return new Response(JSON.stringify(st), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/getStatusWithURL" && urlObj.searchParams.get("url")) {
      var index = urlObj.searchParams.get("url");
      var st = await getStatusofTorrentByTID(index);
  
      return new Response(JSON.stringify(st), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/getAllFiles") {
      var st = await getAllFilesandFolders();
      return new Response(JSON.stringify(st), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/getAllFilesandFoldersandTorrents") {
      var st = await getAllFilesandFoldersandTorrents();
      return new Response(JSON.stringify(st), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
  
  
    if (actionPath == "/getVideos") {
      var st = await getVideos();
      return new Response(JSON.stringify(st), {
        headers: {
          ...crosHeaders,
          "content-type": "application/json"
        }
      });
    }
  
    if (actionPath == "/getVideo") {
      if (!urlObj.searchParams.get("id")) {
        return new Response(JSON.stringify({ status: "SEND VIDEO ID" }), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      } else {
        var st = await getVideo(urlObj.searchParams.get("id"));
        return new Response(JSON.stringify(st), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      }
    }
  
    if (actionPath == "/getFile") {
      if (!urlObj.searchParams.get("id")) {
        return new Response(JSON.stringify({ status: "SEND FILE ID" }), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      } else {
        var st = await getFile(urlObj.searchParams.get("id"));
        return new Response(JSON.stringify(st), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      }
    }
  
    if (actionPath == "/playVid") {
      if (!urlObj.searchParams.get("id")) {
        return new Response(JSON.stringify({ status: "SEND VIDEO ID" }), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      } else {
        var st = await getVideo(urlObj.searchParams.get("id"));
        var uri = st.url_hls;
        var pre = st.url_preroll;
  
        if (urlObj.searchParams.get("embed")) {
          html = `<html>
                  <head>
                   <meta name="viewport" content="width=device-width, initial-scale=1"> 
                      <link href="https://dgbkn.github.io/ninjastream/netflix/final/style.css" rel="stylesheet" />
                  
                  <style type="text/css">
                          html,
                          body {
                              width: 100%;
                              height: 100%;
                              background: #000;
                              overflow: hidden;
                              position: fixed;
                              border: 0;
                              margin: 0;
                              padding: 0;
                          }
                  
                          #player {
                              position: absolute;
                              min-width: 100%;
                              min-height: 100%;
                          }
                  
                          .video-js .vjs-volume-panel .vjs-volume-level:before {
                              top: -0.60em !important;
                          }
                  
                          .jw-logo-button {
                              width: 80px !important;
                          }
                  .jw-aspect {
                      padding-top: 0 !important;
                  }
                          .jw-logo-button>div {
                              width: 100% !important;
                          }
                  
                          @media  only screen and (max-width: 500px) {
                              .jw-logo-button {
                                  width: 50px !important;
                              }
                          }
                  
                      </style> 
                    <style>
                          .icon {
                              display: inline-block;
                              width: 1em;
                              height: 1em;
                              stroke-width: 0;
                              stroke: currentColor;
                              fill: currentColor;
                          }
                  
                      </style>
                    </head>
                  <body>
                    <div class='video'>
                    <script src="https://use.fontawesome.com/20603b964f.js"></script>
                    <script src="https://ssl.p.jwpcdn.com/player/v/8.18.4/jwplayer.js"> </script>
                    <script type="text/javascript">jwplayer.key = 'W7zSm81+mmIsg7F+fyHRKhF3ggLkTqtGMhvI92kbqf/ysE99';</script><div id="player"></div><script type="text/javascript">
                    const playerInstance = 	    jwplayer("player").setup({
                      controls: true,
                      sharing: true,
                      displaytitle: true,
                      displaydescription: true,
                      fullscreen: "true",
                      primary: "html5",
                      stretching: "uniform",
                      aspectratio: "16:9",
                      renderCaptionsNatively: false,
                      autostart: false,
                      abouttext: "Github",
                      aboutlink: "https://github.com/Foilz",
                    
                      skin: {
                        name: "netflix"
                      },
                    
                      logo: {
                        file:
                          "https://cdn.jsdelivr.net/gh/dgbkn/flixyfroontend@main/logo.png"
                      },
                                    image: "${pre}",
                                     width: '100%',
                            file : '${uri}',
                            abouttext: 'FLIXY',
                            playbackRateControls: [0.75, 1, 1.25, 1.5,2.0,2.5]
                                    });
                  
                  playerInstance.on("ready", function () {
                    // Move the timeslider in-line with other controls
                    const playerContainer = playerInstance.getContainer();
                    const buttonContainer = playerContainer.querySelector(".jw-button-container");
                    // const spacer = buttonContainer.querySelector(".jw-spacer");
                    // const timeSlider = playerContainer.querySelector(".jw-slider-time");
                    // buttonContainer.replaceChild(timeSlider, spacer);
                  
                  
                    
                  const player = playerInstance;
                  
                  // display icon
                  const rewindContainer = playerContainer.querySelector('.jw-display-icon-rewind');
                  const forwardContainer = rewindContainer.cloneNode(true);
                  const forwardDisplayButton = forwardContainer.querySelector('.jw-icon-rewind');
                  forwardDisplayButton.style.transform = "scaleX(-1)";
                  forwardDisplayButton.ariaLabel = "Forward 10 Seconds"
                  const nextContainer = playerContainer.querySelector('.jw-display-icon-next');
                  nextContainer.parentNode.insertBefore(forwardContainer, nextContainer);
                  
                  
                  // control bar icon
                  playerContainer.querySelector('.jw-display-icon-next').style.display = 'none'; // hide next button
                  const rewindControlBarButton = buttonContainer.querySelector(".jw-icon-rewind");
                  const forwardControlBarButton = rewindControlBarButton.cloneNode(true);
                  forwardControlBarButton.style.transform = "scaleX(-1)";
                  forwardControlBarButton.ariaLabel = "Forward 10 Seconds";
                  rewindControlBarButton.parentNode.insertBefore(forwardControlBarButton, rewindControlBarButton.nextElementSibling);
                  
                  // add onclick handlers
                  [forwardDisplayButton, forwardControlBarButton].forEach(button => {
                    button.onclick = () => {
                      player.seek((player.getPosition() + 10));
                    }
                  })
                  });
                  
                  </script>
                    </div>
                    </body>
                  </html>`;
  
          return new Response(html, {
            headers: {
              "content-type": "text/html;charset=UTF-8"
            }
          });
        }
  
        return Response.redirect(uri, 301);
      }
    }
  
    if (actionPath == "/download") {
      if (!urlObj.searchParams.get("id")) {
        return new Response(JSON.stringify({ status: "SEND VIDEO/File ID" }), {
          headers: {
            ...crosHeaders,
            "content-type": "application/json"
          }
        });
      } else {
        var st = await getFile(urlObj.searchParams.get("id"));
        var uri = st.url;
        return Response.redirect(uri, 301);
      }
    }
  
  
  
  
  
  
    //UI TEMPLATES
    if (actionPath == "/seeAllFiles") {
      var all = await getAllFilesandFolders();
      html = ``;
  
      for (let i = 0; i < all.length; i++) {
        for (let j = 0; j < all[i].length; j++) {
          var name = all[i][j].name;
          var idi = all[i][j].id;
  
          if (name.includes('.mkv') || name.includes('.mp4')) {
            var extra = `
            <td>
            <a class="waves-effect waves-light btn" href="https://chromecast.link/#title=Playing_Torrent&poster=https%3A%2F%2Fimage.tmdb.org%2Ft%2Fp%2Foriginal%2Fo76ZDm8PS9791XiuieNB93UZcRV.jpg&content=${encodeURIComponent("https://" + currentDomain + "/download?id=" + idi)}">Cast To TV</a>
            </td>
            `;
          } else {
            var extra = '';
          }
  
          html += `<tr>
                  <td>
                  ${name}
                  </td>
                                  
                  <td>
                  <a class="waves-effect waves-light btn" href="//${currentDomain}/download?id=${idi}">Download</a>
                  </td>
                  
                  <td>
                  <a class="waves-effect waves-light btn" href="//${currentDomain}/playVid?id=${idi}&embed=1">Play</a>
                  </td>
                  ${extra}
                  </tr>
                  `;
        }
      }
  
      html = ` <!DOCTYPE html>
          <html>
            <head>
              <!--Import Google Icon Font-->
              <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
              <!--Import materialize.css-->
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
        
              <!--Let browser know website is optimized for mobile-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            </head>
        
            <body class="container">
        <h4>All Files</h4><table>
        ${html}
        </table>
        <br>
        
        <a class="waves-effect waves-light btn" href="//${currentDomain}">Go Back</a>
        
        
              <!--JavaScript at end of body for optimized loading-->
            <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
            </body>
          </html>`;
  
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8"
        }
      });
    }
  
  
  
    if (actionPath == "/addMagnet" && urlObj.searchParams.get("magnet")) {
  
      await deleteAll();
  
      var addMag = await addMagnet(urlObj.searchParams.get("magnet"));
  
      if (addMag.code != 200) {
        html = ` <!DOCTYPE html>
          <html>
            <head>
              <!--Import Google Icon Font-->
              <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
              <!--Import materialize.css-->
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
        
              <!--Let browser know website is optimized for mobile-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            </head>
        
            <body class="container">
            <h3>ERROR : ${addMag.result} (Check Magnet Link)...</h3>
  
            <br>
                  
        <a class="waves-effect waves-light btn" href="//${currentDomain}">Go Back</a>
        
        
              <!--JavaScript at end of body for optimized loading-->
            <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
            </body>
          </html>`;
  
      } else {
  
        html = ` <!DOCTYPE html>
      <html>
        <head>
          <!--Import Google Icon Font-->
          <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
          <!--Import materialize.css-->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
    
          <!--Let browser know website is optimized for mobile-->
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        </head>
    
        <body class="container">
        <h4>Please Wait Downloading ${addMag.title} </h4>
        <br>
        <h4 id="progress" >Progress: 0% </h4>
    
        <br>
        <a class="waves-effect waves-light btn" href="//${currentDomain}">Go Back</a>
        <a class="waves-effect waves-light btn" href="//${currentDomain}/deleteAll">Delete ALL (reset) </a>
  
        <script type="text/javascript">
  
        function makeRequest(method, url) {
            return new Promise(function (resolve, reject) {
                let xhr = new XMLHttpRequest();
                xhr.open(method, url);
                xhr.onload = function () {
                    if (this.status >= 200 && this.status < 300) {
                        resolve({
                            status: this.status,
                            statusText: xhr.statusText,
                            responseText: xhr.responseText
                        });
                    } else {
                        reject({
                            status: this.status,
                            statusText: xhr.statusText
                        });
                    }
                };
                xhr.onerror = function () {
                    reject({
                        status: this.status,
                        statusText: xhr.statusText
                    });
                };
                xhr.send();
            });
        }
  
  
        setInterval(checkStatus, 2500);
  
        
        function checkStatus(){
          makeRequest("GET", "/getStatus").then(async (response) => {
  
              if (response.status == 200) {
                  console.log(response.responseText);
                  var progdata = JSON.parse(response.responseText);
  
                  localStorage.setItem('progdata', JSON.stringify(progdata));
  
                  //if(progdata.status){
                 //   location.replace("/slowSpeed");
                //  }
  
                  var vids = await makeRequest("GET","/getVideos");
  
                  if ((progdata.warnings && progdata.warnings != '[]' && !vids) || progdata.download_rate == 0 ) {
                  var vids = await makeRequest("GET","/deleteAll");
                  location.replace("/slowSpeed");
                  }
  
                  var prog = progdata.progress;
  
                  if(progdata.status){
                    location.replace("/seeAllFiles");
                  }
  
                  document.getElementById("progress").innerHTML = "Progress: " + prog + "%";
              }
          })
        }
  
  
        const myTimeout = setTimeout(myGreeting, 15000);
        
  async function myGreeting() {
    var pr = JSON.parse(localStorage.getItem("progdata"));
    if ( !('status' in pr) && !('download_rate' in pr) && !('progress' in pr) ) {
    var vids = await makeRequest("GET","/deleteAll");
    location.replace("/slowSpeed");
  }
      }
        </script>
  
  
    
    <br>
      
          <!--JavaScript at end of body for optimized loading-->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
        </body>
      </html>`;
  
  
      }
  
  
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8"
        }
      });
    }
  
  
    if (actionPath == "/slowSpeed") {
  
      html = ` <!DOCTYPE html>
          <html>
            <head>
              <!--Import Google Icon Font-->
              <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
              <!--Import materialize.css-->
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
        
              <!--Let browser know website is optimized for mobile-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            </head>
        
            <body class="container">
            <h3>ERROR : SLOW TORRENT DETECTED CHECK SEEDS</h3>
            <br>
        <a class="waves-effect waves-light btn" href="//${currentDomain}">Go Back</a>
        
              <!--JavaScript at end of body for optimized loading-->
            <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
            </body>
          </html>`;
  
  
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8"
        }
      });
    }
  
  
    //UI TEMPLATES
  
  
  
  
  
  
  
  
  
    return new Response(JSON.stringify({ status: "NOT FOUND 404" }), {
      headers: {
        ...crosHeaders,
        "content-type": "application/json"
      }
    });
  }
  
  //seedr API
  
  async function getToken() {
    var details = {
      grant_type: "password",
      client_id: "seedr_chrome",
      type: "login",
      username: "anandrambkn@gmail.com",
      password: "@Anu2240013"
    };
  
    const rawResponse = await fetch("https://www.seedr.cc/oauth_test/token.php", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
      },
      body: jsonToformEncoded(details)
    });
  
    const content = await rawResponse.json();
  
    var token = content.access_token;
  
    await SEEDR_DB.put("token", token, { expirationTtl: content.expires_in });
  
    return token;
  }
  
  async function fetchWithToken(url) {
    var token = await SEEDR_DB.get("token");
  
    if (!token) {
      console.log("REGENERATION OF ACCESS_TOKEN");
      token = await getToken();
    }
  
    var tokenfetch = await fetch(url + "?access_token=" + token);
    var tokenfetch = await tokenfetch.json();
    return tokenfetch;
  }
  
  async function fetchpostWithToken(url, data) {
    var token = await SEEDR_DB.get("token");
  
    if (!token) {
      console.log("REGENERATION ACCESS_TOKEN");
      token = await getToken();
    }
  
    data = { ...data, access_token: token };
  
    const rawResponse = await fetch(url, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
      },
      body: jsonToformEncoded(data)
    });
  
    const content = await rawResponse.json();
    return content;
  }
  
  async function getVideos() {
    var res = [];
  
    var data = await fetchWithToken("https://www.seedr.cc/api/folder");
  
    for (var folder of data.folders) {
      res.push(
        (
          await fetchWithToken("https://www.seedr.cc/api/folder/" + folder.id)
        ).files
          .filter((x) => x["play_video"])
          .map((x) => {
            return {
              fid: folder.id,
              id: x["folder_file_id"],
              name: x.name
            };
          })
      );
    }
  
    return res;
  }
  
  async function getAllFilesandFolders() {
    var res = [];
  
    var data = await fetchWithToken("https://www.seedr.cc/api/folder");
  
    for (var folder of data.folders) {
      res.push(
        (
          await fetchWithToken("https://www.seedr.cc/api/folder/" + folder.id)
        ).files
          .filter((x) => x)
          .map((x) => {
            return {
              fid: folder.id,
              id: x["folder_file_id"],
              name: x.name
            };
          })
      );
    }
  
    return res;
  }
  
  async function getAllFilesandFoldersandTorrents() {
    var data = await fetchWithToken("https://www.seedr.cc/api/folder");
    return data;
  }
  
  async function getFolders() {
    var data = { func: "list_contents", content_type: "folder", content_id: "0" };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function getSettings() {
    var data = { func: "get_settings" };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function getBandwidth() {
    var data = { func: "get_memory_bandwidth" };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function renameFolder(name, id) {
    var data = { func: "rename", rename_to: name, folder_id: id };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function renameFile(name, id) {
    var data = { func: "rename", rename_to: name, file_id: id };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function getFile(id) {
    var data = { func: "fetch_file", folder_file_id: id };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    if (!res) {
      res = { status: "not found" };
    }
    return res;
  }
  
  async function getVideo(id) {
    var data = { func: "play_video", folder_file_id: id };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    if (!res) {
      res = { status: "not found" };
    }
    return res;
  }
  
  async function addMagnet(magnet) {
    var data = { func: "add_torrent", torrent_magnet: magnet };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function deleteFolder(id) {
    var data = {
      func: "delete",
      delete_arr: JSON.stringify([
        {
          type: "folder",
          id: id
        }
      ])
    };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function deleteFile(id) {
    var data = {
      func: "delete",
      delete_arr: JSON.stringify([
        {
          type: "file",
          id: id
        }
      ])
    };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function deleteTorrent(id) {
    var data = {
      func: "delete",
      delete_arr: JSON.stringify([
        {
          type: "torrent",
          id: id
        }
      ])
    };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function deleteAll() {
    var all = await getAllFilesandFoldersandTorrents();
    torrents = all.torrents;
    folders = all.folders;
  
    for (var each of folders) {
      await deleteFolder(each.id);
    }
  
    for (var each of torrents) {
      await deleteTorrent(each.id);
    }
  }
  
  async function getStatusofTorrent(index = 0) {
    var all = await getAllFilesandFoldersandTorrents();
    torrents = all.torrents;
  
    if (0 in torrents) {
      var progress = torrents[index]["progress_url"];
      var tid = torrents[index]["id"];
  
      var statusFetch = await fetch(progress);
      var progdata = await statusFetch.text();
  
      progdata = progdata.substring(1);
      progdata = progdata.substring(1);
      progdata = progdata.slice(0, -1);
  
      return JSON.parse(progdata);
    } else {
      return { status: "No Torrent There To Show Status" };
    }
  }
  
  async function getStatusofTorrentByTID(index = 0) {
  
    var res = await fetch(
      index,
    );
  
    var progdata = await res.text();
  
    progdata = progdata.substring(1);
    progdata = progdata.substring(1);
    progdata = progdata.slice(0, -1);
  
    return JSON.parse(progdata);
  
  }
  
  async function search(qry) {
    var data = { func: "search_files", search_query: qry };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  async function getFilesofFolders(fid) {
    var data = { func: "list_contents", content_type: "folder", content_id: fid };
    var res = await fetchpostWithToken(
      "https://www.seedr.cc/oauth_test/resource.php",
      data
    );
    return res;
  }
  
  //seedr API
  
  //UTILS
  function jsonToformEncoded(json) {
    var formBody = [];
    for (var property in json) {
      var encodedKey = encodeURIComponent(property);
      var encodedValue = encodeURIComponent(json[property]);
      formBody.push(encodedKey + "=" + encodedValue);
    }
    formBody = formBody.join("&");
    return formBody;
  }
  
  //UTILS
  