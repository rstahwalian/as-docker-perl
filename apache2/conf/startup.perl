#!/usr/bin/perl
use strict;
use warnings;

use lib qw(
    /dwc/codelibrary
    /dwc/codelibrary/CLDB/
    /dwc/codelibrary.dtss/WI
    /dwc/codelibrary/Genie5.0/g5-bin/perllib
    /dwc/codelibrary/EFT/perllib
    /dwc/codelibrary/TicketCentral
    /dwc/codelibrary/CLFIN/global
    /dwc/codelibrary/CLFIN/payments
    /dwc/lakeconference/g5-bin/perllib
);

use ModPerl::RegistryPrefork;
# use ModPerl::Registry;
use Apache2::RequestRec ();
use Apache2::RequestIO ();

use CGI ();
CGI->compile(':all');

use DBI ();
use DBD::mysql;

use Date::Format;
use Image::Magick;
use Net::SMTP;
use Time::Local;

#
# --- G5 common modules ---
#
use G5::Admin;
use G5::Client;
use G5::Setup;
use G5::Common;

use CLFile::Template;
use CLFile::Transfer;
use CLDB::DBAccess;
use CLDB::Utils;
use CLUtils::Text;
use CLUtils::Security;
use CLUtils::MoveAfter;
use CLHTML::Utils;

use G5::Plugins::textProp;
use G5::Plugins::lib::last_updated;
use G5::Plugins::datePulldown;

use G5Local::Security;

#
# --- G5 Plugins and Tasks ---
#
use G5::Plugins::Directory;
use G5::Plugins::Multiscript;
use G5::Plugins::MultiscriptAdvanced;
use G5::Plugins::tracker;

#
# --- LC modules
#
use G5::Plugins::LC::Client;
use G5::Plugins::LC::Setup;
use G5::Plugins::LC::Tasks::Content;
use G5::Plugins::LC::Tasks::Extras;
use G5::Plugins::LC::Tasks::Reports;
use G5::Plugins::LC::Tasks::Aliases;
use G5::Plugins::LC::Tasks::Policies;
use G5::Plugins::LC::Tasks::Committees;
use G5::Plugins::LC::Admin;
use G5::Plugins::LC::Common;
use G5::Plugins::LC::Security;
use G5::Plugins::LC::Preferences;
use G5::Plugins::LC::SeasonsWorksheets;
use G5::Plugins::LC::Transportation;
use G5::Plugins::LC::GeneralSchoolInfo;
use G5::Plugins::LC::Rosters;
use G5::Plugins::LC::ScoresStandings;
use G5::Plugins::LC::Contracts;
use G5::Plugins::LC::GlobalPostpone;
use G5::Plugins::LCcalendar;

1;