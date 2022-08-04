%global debug_package %{nil}

# macro to filter unwanted provides from Node.js binary native modules
%nodejs_default_filter

Name: sass
Epoch: 100
Version: 1.54.3
Release: 1%{?dist}
BuildArch: noarch
Summary: A pure JavaScript implementation of Sass
License: MIT
URL: https://github.com/sass/dart-sass/tags
Source0: %{name}_%{version}.orig.tar.gz
BuildRequires: fdupes
BuildRequires: nodejs-packaging
Requires: nodejs >= 12.0.0

%description
A Dart implementation of Sass. Sass makes CSS fun again.

%prep
%autosetup -T -c -n %{name}_%{version}-%{release}
tar -zx -f %{S:0} --strip-components=1 -C .

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{nodejs_sitelib}
cp -rfT node_modules %{buildroot}%{nodejs_sitelib}
pushd %{buildroot}%{_bindir} && \
    ln -fs %{nodejs_sitelib}/sass/sass.js sass && \
    popd
chmod a+x %{buildroot}%{nodejs_sitelib}/sass/sass.js
fdupes -qnrps %{buildroot}%{nodejs_sitelib}

%check

%files
%license LICENSE
%dir %{nodejs_sitelib}
%{_bindir}/*
%{nodejs_sitelib}/*

%changelog
