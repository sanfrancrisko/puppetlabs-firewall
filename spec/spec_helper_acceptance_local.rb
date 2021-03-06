require 'singleton'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

def iptables_flush_all_tables
  ['filter', 'nat', 'mangle', 'raw'].each do |t|
    expect(run_shell("iptables -t #{t} -F").stderr).to eq('')
  end
end

def ip6tables_flush_all_tables
  ['filter', 'mangle'].each do |t|
    expect(run_shell("ip6tables -t #{t} -F").stderr).to eq('')
  end
end

def install_iptables
  run_shell('iptables -V')
rescue
  run_shell('apt-get install iptables -y')
end

def iptables_version
  install_iptables
  x = run_shell('iptables -V')
  x.stdout.split(' ')[1][1..-1]
end

def pre_setup
  run_shell('mkdir -p /lib/modules/`uname -r`')
  run_shell('depmod -a')
end

def update_profile_file
  run_shell("sed -i '/mesg n/c\\test -t 0 && mesg n || true' ~/.profile")
  run_shell("sed -i '/mesg n || true/c\\test -t 0 && mesg n || true' ~/.profile")
end

RSpec.configure do |c|
  c.before :suite do
    if os[:family] == 'debian' && os[:release].to_i == 10
      pp = <<-PUPPETCODE
        package { 'net-tools':
          ensure   => 'latest',
        }
        package { 'iptables':
          ensure   => 'latest',
        }
        PUPPETCODE
      LitmusHelper.instance.apply_manifest(pp)
      LitmusHelper.instance.run_shell('update-alternatives --set iptables /usr/sbin/iptables-legacy', expect_failures: true)
      LitmusHelper.instance.run_shell('update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy', expect_failures: true)
    end
    pp = <<-PUPPETCODE
      package { 'conntrack-tools':
        ensure => 'latest',
      }
    PUPPETCODE
    LitmusHelper.instance.apply_manifest(pp)
  end
end
