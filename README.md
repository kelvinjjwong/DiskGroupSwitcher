#  DiskGroupSwitcher

## Background

A macOS desktop tool to help switch between group of SSD and group of HDD for energy saving & noise reduction purpose. (Disk enclosures are noisy)

It might be a strange environment setting in my (author's) home. First of all, I have 4 macs:

- kelvinstation (running macOS 14)
- photostation (running macOS 12 with Plex Media Server)
- musicstation (running macOS 12 with Plex Media Server)
- mediastation (running macOS 10.15 with Plex Media Server)

ummm....why not use a single Plex Media Server? Maybe because it's too slooooooow on indexing files.

Each mac connects a set of SSD for faster read/write and a set of HDD for backup purpose. They're 1:1 mapping, scheduled backup by *Carbon Copy Cloner*. To avoid confused by Plex Media Server, I use soft links to specify set of disks for read/write, i.e. when I would like faster access I would point them to SSD, otherwise I would point them to HDD, or shut down all of them. Before shutting down either set of disks, I should firstly unmount the volumes, and then shut down the enclosure. Luckily these enclosures connecting to Apple Home could be turn on/off by Siri. Obviously sometimes I need to handle 8 sets of disks and feel that would be a big trouble on time spending. So I write this tool to automate most of the switch over operations. Yes that sounds like a quite strange setting even after I write it out..


## Dependency

- require macOS 10.15+ , however textfield is not editable in macOS 10.15 and 12.x
- require Swift >= 5.9

*last built with Xcode 15.0.1 in macOS 14.1.1*

- Dependencies:
  - LoggerFactory
  - FlyingFox as http server
  - Alamofire as http client




