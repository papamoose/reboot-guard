Name:           reboot-guard
Version:        1.0
Release:        1%{?dist}
Summary:        Reboot guard that requires the operator to type the machine name

License:        MIT
URL:            https://pklan.org
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash >= 4.0

%description
reboot-guard installs a wrapper at /usr/local/sbin/reboot.
Before the machine reboots, the operator types the name of the
machine. A wrong name cancels the reboot. The wrapper never
changes /sbin/reboot. Calling /sbin/reboot reboots without a
prompt. This is an operational guardrail, not a security control.

%prep
%setup -q

%build
# Nothing to build. The package ships one bash script.

%install
install -d %{buildroot}/usr/local/sbin
install -m 0755 reboot %{buildroot}/usr/local/sbin/reboot

%check
bash -n %{buildroot}/usr/local/sbin/reboot

%files
/usr/local/sbin/reboot

%changelog
* Thu Sep 24 2026 Philip Kauffman - 1.0-1
- Initial package.
