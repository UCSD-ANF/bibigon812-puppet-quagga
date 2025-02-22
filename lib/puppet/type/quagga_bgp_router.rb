Puppet::Type.newtype(:quagga_bgp_router) do
  @doc = "

    This type provides the capability to manage bgp parameters within puppet.

      Examples:

        quagga_bgp_router { 'bgp':
            ensure                   => present,
            as_number                => 65000,
            import_check             => true,
            default_ipv4_unicast     => false,
            default_local_preference => 100,
            router_id                => '192.168.1.1',
            keepalive                => 3,
            holdtime                 => 9,
        }
  "

  ensurable

  newparam(:name, namevar: true) do
    desc 'BGP router instance.'

    munge do |_value|
      'bgp'
    end
  end

  newproperty(:as_number) do
    desc 'The AS number.'

    validate do |value|
      raise "Invalid value '#{value}'. It is not an Integer" unless value.is_a?(Integer)
      raise "Invalid value '#{value}'. Valid values are 1-4294967295" unless (value >= 1) && (value <= 4_294_967_295)
    end
  end

  newproperty(:import_check, boolean: true) do
    desc 'Check BGP network route exists in IGP.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:default_ipv4_unicast, boolean: true) do
    desc 'Activate ipv4-unicast for a peer by default.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:default_local_preference) do
    desc 'Default local preference.'
    defaultto(100)

    validate do |value|
      raise "Invalid value '#{value}'. It is not an Integer" unless value.is_a?(Integer)
      raise "Invalid value '#{value}'. Valid values are 0-4294967295" unless (value >= 0) && (value <= 4_294_967_295)
    end
  end

  newproperty(:redistribute, array_matching: :all) do
    desc 'Redistribute information from another routing protocol.'

    defaultto([])
    newvalues(%r{\A(babel|connected|isis|kernel|ospf|rip|static)(\smetric\s\d+)?(\sroute-map\s\w+)?\Z})

    def insync?(is)
      @should.each do |value|
        return false unless is.include?(value)
      end

      is.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def to_s?(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end
  end

  newproperty(:router_id) do
    desc 'Override configured router identifier.'

    block = %r{\d{,2}|1\d{2}|2[0-4]\d|25[0-5]}
    re = %r{\A#{block}\.#{block}\.#{block}\.#{block}\Z}

    newvalues(re)
  end

  newproperty(:keepalive) do
    desc 'Default BGP keepalive interval.'
    defaultto(3)

    validate do |value|
      raise "Invalid value '#{value}'. It is not an Integer" unless value.is_a?(Integer)
      raise "Invalid value '#{value}'. Valid values are 0-65535" unless (value >= 0) && (value <= 65_535)
    end
  end

  newproperty(:holdtime) do
    desc 'Default BGP holdtime.'
    defaultto(9)

    validate do |value|
      raise "Invalid value '#{value}'. It is not an Integer" unless value.is_a?(Integer)
      raise "Invalid value '#{value}'. Valid values are 0-65535" unless (value >= 0) && (value <= 65_535)
    end
  end

  validate do
    raise 'keepalive must be 0 or at least three times greater than holdtime' if (value(:keepalive) != 0) && (value(:keepalive) > value(:holdtime) / 3)
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'bgpd']
  end
end
