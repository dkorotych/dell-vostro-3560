# dell-vostro-3560
[Gentoo](https://gentoo.org/) overlay for hardware support for Dell Vostro 3560

## How to use this overlay
### With Layman

Invoke the following:
```
sudo layman -o https://raw.github.com/dkorotych/dell-vostro-3560/master/repositories.xml -f -a dell-vostro-3560
```
Or read the instructions on the [Gentoo Wiki](http://wiki.gentoo.org/wiki/Layman#Adding_custom_overlays).

### With local overlays

[Local overlays](https://wiki.gentoo.org/wiki/Overlay/Local_overlay) should be managed via `/etc/portage/repos.conf/`.
To enable this overlay make sure you are using a recent Portage version (at least `2.2.14`), and create a `/etc/portage/repos.conf/dell-vostro-3560-overlay.conf` file containing precisely:

```
[dell-vostro-3560]
location = /usr/local/portage/dell-vostro-3560
sync-type = git
sync-uri = https://github.com/dkorotych/dell-vostro-3560.git
```
Afterwards, simply run `emerge --sync`, and Portage should seamlessly make all our datas available.
