# This Makefile contains 2 main sections
#  - Variables
#  - targets

# ---------
# VARIABLES
# ---------

SHELL = /bin/bash
# Prefix for packaging
DESTDIR=

# Default directories install
# ---------------------------

## Common dirs
# Prefix
PREFIX=/usr/local
FBPREFIX=$(PREFIX)/fingerbank
PFPREFIX=$(PREFIX)/pf

# Fingerbank
LOGDIR=$(FBPREFIX)/logs
CONFDIR=$(FBPREFIX)/conf

# PF
PFBINDIR=$(PFPREFIX)/bin

# Commands
PFCMD_BIN=$(PFBINDIR)/pfcmd

FBUSER=fingerbank
FBGROUP=fingerbank


VERSION=


# ---------
# TARGETS
# ---------


init-db-local:
	@db/upgrade.pl --database db/fingerbank_Local.db; \
	chown fingerbank.fingerbank /usr/local/fingerbank/db/fingerbank_Local.db; \
	chmod 664 /usr/local/fingerbank/db/fingerbank_Local.db; \

init-db-upstream:
	@read -p "API key (ENTER if none): " api_key; \
	perl -I/usr/local/fingerbank/lib -Mfingerbank::DB -Mfingerbank::Util -Mfingerbank::Log -e "fingerbank::Log::init_logger; fingerbank::DB::update_upstream( (api_key => \"$$api_key\") )"; \
	chown fingerbank.fingerbank /usr/local/fingerbank/db/fingerbank_Upstream.db; \
	chmod 664 /usr/local/fingerbank/db/fingerbank_Upstream.db; \

package-files:
	@read -p "Version (X.Y.Z): " version; \
	read -p "From Branch: " branch; \
	tmp_dir=fingerbank-$$version; \
	echo Building package files tgz for fingerbank-$$version; \
	if [ -d $$tmp_dir ]; then \
		echo "Destination for git clone ($$tmp_dir) already exists"; \
	else \
		mkdir $$tmp_dir; \
		git clone https://github.com/fingerbank/perl-client.git $$tmp_dir; \
		if [ -n $$branch ]; then \
			cd $$tmp_dir ; \
			git checkout $$branch ; \
			cd .. ; \
		fi ; \
		rm -f $$tmp_dir/README.md; \
		rm -rf $$tmp_dir/t; \
		read -p "API key: " api_key; \
		perl -I$$tmp_dir/lib -Mfingerbank::DB -Mfingerbank::Util -Mfingerbank::Log '-MLog::Log4perl qw(:easy)' -e "Log::Log4perl->easy_init(\$$INFO); fingerbank::DB::update_upstream( (api_key => \"$$api_key\", destination => \"$$tmp_dir/db/fingerbank_Upstream.db\") )"; \
		tar -czf fingerbank.tar.gz $$tmp_dir; \
		rm -rf $$tmp_dir; \
	fi \

package-files-standalone:
	@read -p "Version (X.Y.Z): " version; \
	read -p "From Branch: " branch; \
	tmp_dir=fingerbank-$$version; \
	echo Building package files tgz for fingerbank-$$version; \
	if [ -d $$tmp_dir ]; then \
		echo "Destination for git clone ($$tmp_dir) already exists"; \
	else \
		mkdir $$tmp_dir; \
		git clone https://github.com/fingerbank/perl-client.git $$tmp_dir; \
		if [ -n $$branch ]; then \
			cd $$tmp_dir ; \
			git checkout $$branch ; \
			cd .. ; \
		fi ; \
		rm -f $$tmp_dir/README.md; \
		rm -rf $$tmp_dir/t; \
		read -p "API key: " api_key; \
		curl -X GET  https://api.fingerbank.org/api/v2/download/db?key=$$api_key --output $$tmp_dir/db/fingerbank_Upstream.db; \
		tar -czf fingerbank.tar.gz $$tmp_dir; \
		rm -rf $$tmp_dir; \
	fi \

package-debian:
	sudo apt-get install git dpkg-dev debhelper sudo curl -y; \
	read -p "Version: " DEB_VERSION; \
	read -p "From Branch: " branch; \
	tmp_dir=fingerbank-$$DEB_VERSION; \
	if [ -d $$tmp_dir ]; then \
		echo "Destination for git clone ($$tmp_dir) already exists"; \
	else \
		mkdir $$tmp_dir; \
		git clone https://github.com/fingerbank/perl-client.git $$tmp_dir; \
		if [ -n $$branch ]; then \
			cd $$tmp_dir ; \
			git checkout $$branch ; \
			cd .. ; \
		fi ; \
		read -p "API key: " api_key; \
		curl -X GET  https://api.fingerbank.org/api/v2/download/db?key=$$api_key -H 'Accept-Encoding: gzip, deflate, sdch, br' --compressed --keepalive-time 3 --retry 5 --output $$tmp_dir/db/fingerbank_Upstream.db; \
		cp $$tmp_dir/db/fingerbank_Upstream.db db/fingerbank_Upstream.db; \
		tar cvfj ../fingerbank_$$DEB_VERSION.orig.tar.bz2 $$tmp_dir; \
		rm -rf $$tmp_dir; \
		echo run dpkg-buildpackage -rfakeroot to build the package; \
	fi \

reset-db-handles:
		@perl -I/usr/local/fingerbank/lib -Mfingerbank::DB -Mfingerbank::Util -Mfingerbank::Log -e "fingerbank::Log::init_logger; fingerbank::Util::reset_db_handles"; \

fixpermissions:
	@perl -I/usr/local/fingerbank/lib -Mfingerbank::DB -Mfingerbank::Util -Mfingerbank::Log -e "fingerbank::Log::init_logger; fingerbank::Util::fix_permissions"; \

test:
	FINGERBANK_KEY=$$api_key perl t/smoke.t

full-test:
	@read -p "API key (ENTER if none): " api_key; \
	FINGERBANK_KEY=$$api_key perl t/smoke.t
