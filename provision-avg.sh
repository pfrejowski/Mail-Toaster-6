#!/bin/sh

. mail-toaster.sh || exit

install_avg()
{
	# TODO
#	mkdir /tmp/avg $JAILS_MNT/avg/var/tmp/avg $JAILS_MNT/haraka/var/tmp/avg || exit
#	sed -i.bak -e 's/#mount +=  "\/tmp\/avg/mount +=  "\/tmp\/avg/' /etc/jail.conf

	stage_exec make -C /usr/ports/misc/compat7x install distclean
	stage_fbsd_package lib32
	fetch -o $STAGE_MNT/usr/lib32/libiconv.so.3 http://mail-toaster.org/install/libiconv.so.3

	sysrc -R $STAGE_MNT ldconfig32_paths="\$ldconfig32_paths /opt/avg/av/lib"
	mkdir -p $STAGE_MNT/usr/local/etc/rc.d || exit

	fetch -m http://download.avgfree.com/filedir/inst/avg2013ffb-r3115-a6155.i386.tar.gz || exit
	tar -C $STAGE_MNT/tmp -xzf avg2013ffb-r3115-a6155.i386.tar.gz || exit
	jexec $SAFE_NAME /tmp/avg2013ffb-r3115-a6155.i386/install.sh
}

configure_avg()
{
	stage_exec avgcfgctl -w Default.aspam.spamassassin.enabled="false"
	stage_exec avgcfgctl -w Default.tcpd.avg.address="0.0.0.0"
	stage_exec avgcfgctl -w Default.tcpd.smtp.enabled="false"
	stage_exec avgcfgctl -w Default.tcpd.spam.enabled="false"
	stage_exec avgcfgctl -w Default.setup.features.oad="false"
}

start_avg()
{
	stage_exec service avgd.sh restart
	sleep 1
}

test_avg()
{
	echo "testing AVG process is running"
	ps ax -J $SAFE_NAME | grep avg || exit

	echo "checking avgtcpd is listening"
	sleep 1
	sockstat -l | grep 54322 || exit
}

base_snapshot_exists \
	|| (echo "$BASE_SNAP must exist, use provision-base.sh to create it" \
	&& exit)

create_staged_fs avg
stage_sysrc hostname=avg
start_staged_jail
install_avg
configure_avg
start_avg
test_avg
promote_staged_jail avg