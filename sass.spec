# Copyright 2024 Wong Hoi Sing Edison <hswong3i@pantarei-design.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

%global debug_package %{nil}

%global source_date_epoch_from_changelog 0

# macro to filter unwanted provides from Node.js binary native modules
%nodejs_default_filter

Name: sass
Epoch: 100
Version: 1.79.2
Release: 1%{?dist}
BuildArch: noarch
Summary: A pure JavaScript implementation of Sass
License: MIT
URL: https://github.com/sass/dart-sass/tags
Source0: %{name}_%{version}.orig.tar.gz
BuildRequires: fdupes
BuildRequires: nodejs-packaging

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
