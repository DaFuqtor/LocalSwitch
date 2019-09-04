<h1 align="center">
  LocalSwitch <img align="center" height="64" width="64" src="LocalSwitch/Assets.xcassets/AppIcon.appiconset/Mac128x1.png">
</h1>

<blockquote align="center">
  <p><b>
    Menu bar interface for a local Apache <code>httpd</code> server.
  </b></p>
</blockquote>

<br>

<a align="left" href="//app.bitrise.io/app/0769bd3b0356ebfb"><img align="left" alt="Build status" src="https://app.bitrise.io/app/0769bd3b0356ebfb/status.svg?token=YB1MFGU_HjycQbCYYvbywQ"></a>

<a align="right" href="//github.com/DaFuqtor/LocalSwitch/releases"><img align="right" alt="GitHub All Releases" src="https://img.shields.io/github/downloads/dafuqtor/localswitch/total"></a>

<p align="center">LocalSwitch is an open source macOS interface for <code>apachectl</code> written in Swift.</p>

![preview](preview.png)

<h2 align="center">
  <a href="//github.com/DaFuqtor/LocalSwitch/releases/latest/download/LocalSwitch.zip">
    Download latest release &nbsp
    <a href="//github.com/DaFuqtor/LocalSwitch/releases/latest">
      <img align="center" alt="GitHub release" src="https://img.shields.io/github/release/dafuqtor/localswitch?label">
    </a>
  </a>
</h2>

### [Homebrew Cask](//brew.sh) (Recommended)

```powershell
brew cask install dafuqtor/tap/localswitch
```

### Quick Installation

> This script just downloads LocalSwitch to the `Applications` folder. Additionaly, you **lose** auto-updates.

```powershell
curl -sL git.io/localswitchinst | sh
```

<br>

## Usage :mag:

Things shown in menu are obvious, but you need to know some more:

#### Status Item actions

- RMB click · visit `<username>.local`
  
  > if the server is off, turns it on

- Double click · open `~/Sites/` folder

  > dragging a file over the Status Item does the same thing

- [MiddleClick](//github.com/DaFuqtor/MiddleClick-Catalina) · switch server state

#### Spotlight action

Switch server state using [Spotlight Search](//support.apple.com/en-us/HT204014)

> or just open LocalSwitch when it's **already running**

<p><kbd>⌘</kbd><kbd>Space</kbd> &nbsp·&nbsp type <code>ls</code> &nbsp·&nbsp hit <kbd>Enter</kbd>&nbsp</p>
