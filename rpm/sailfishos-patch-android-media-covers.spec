Name:       sailfishos-patch-android-media-covers
Summary:    Patchmanager patch: media controls on Android app covers
Version:    0.2.1
Release:    1
License:    GPLv3+
BuildArch:  noarch
Source0:    %{name}-%{version}.tar.bz2

Requires:   patchmanager >= 3.0
# The patched file and what the patch imports. Which OS releases the diff
# applies to is patch.json's "compatible", checked by Patchmanager.
Requires:   lipstick-jolla-home-qt5
Requires:   amber-qml-plugin-mpris
# the icon of the "back 30 s" cover action is an SVG
Requires:   qt5-qtsvg-plugin-imageformat-svg

%description
A Patchmanager patch: Android apps that play media get a cover of their own
in the app switcher, with the artwork, the title and the chapter or artist,
and play/pause and next as cover actions. It uses the MPRIS players that
Android App Support creates for the apps' media sessions.

%prep
%setup -q -n %{name}-%{version}

%build

%install
# %%{_sourcedir} is the checkout's rpm/ directory, also when sfdk builds out of tree
mkdir -p %{buildroot}%{_datadir}/patchmanager/patches/%{name}
cp -a %{_sourcedir}/../patch/unified_diff.patch %{_sourcedir}/../patch/patch.json \
    %{buildroot}%{_datadir}/patchmanager/patches/%{name}/
# files the patched QML uses
mkdir -p %{buildroot}%{_datadir}/%{name}
cp -a %{_sourcedir}/../icons/icon-cover-replay-30.svg %{buildroot}%{_datadir}/%{name}/

# Unapply before an upgrade replaces the diff and before removal, as
# Patchmanager could not unapply a diff it no longer has.
%pre
if [ "$1" -gt 1 ] && [ -x /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u %{name} || true
fi

%preun
if [ -x /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u %{name} || true
fi

%files
%defattr(-,root,root,-)
%{_datadir}/patchmanager/patches/%{name}
%{_datadir}/%{name}
