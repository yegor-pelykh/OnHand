<p align="center">
  <img src="web/icons/icon-128.png" width="128" />
</p>

# OnHand

I present to you my browser extension, created for easy and convenient management of your favorite sites, which can be opened directly from a browser "new tab" page.

Neat and minimalistic.
Uses material design.

Features:
- adding bookmarks in a simple way
- grouping bookmarks using tabs
- easy data management, loading and saving to a file, without clouds and accounts
- supports switching between light and dark theme (it depends on the theme color of the operating system)
- can be run in any browser that supports WebExtension API, such as:
  * Google Chrome
  * Opera
  * Firefox
  * Edge
  * Chromium
  * etc.

Currently, there are such restrictions on the use of this add-on:
- only English interface language is supported
- this addon was made only for desktop browsers

## Usage Notes

Just a few words about opening added bookmarks. 😉

By **clicking on a bookmark**, the website will be opened **in the same tab** by default.<br>
But when you **hold down the Ctrl key**, the browser will open the website **in a new background tab**.

## Screenshots

Light mode:<br>
<img src="app_info/screenshot_light.png" width="600" />
<br>Dark mode:<br>
<img src="app_info/screenshot_dark.png" width="600" />

## Build

You can easily build the release version of this browser extension.
1. Please make sure you have Node.js installed on your computer. If it is not installed yet, download it from the [Node.js official site](https://nodejs.org) and install it.
2. To build on **Windows**: just run the file `release_build.bat` at the root of the project.<br>
Otherwise, to build on **any desktop platform**, use this list of commands:
    ```properties
    flutter clean
    flutter pub get
    flutter build web --web-renderer html --csp
    npm install
    node harmonization.js
    ```