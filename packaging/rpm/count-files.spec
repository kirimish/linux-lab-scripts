Name:           count-files
Version:        1.0
Release:        1%{?dist}
Summary:        Script to count regular files in /etc
License:        GPLv3+
URL:            https://github.com/kirimish/linux-lab-scripts
Source0:        count-files-1.0.tar.gz
BuildArch:      noarch
Requires:       bash, coreutils, findutils

%description
A Bash script that counts the number of regular files in the /etc directory.

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
install -m 0755 count_files.sh %{buildroot}/usr/bin/count_files

%files
/usr/bin/count_files

%changelog
* Thu Dec 18 2025 Kirienko Mykhailo <fhidxh7@gmail.com> - 1.0-1
- Initial package release
