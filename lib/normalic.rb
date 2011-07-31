#only handles U.S addresses
require 'constants'
require 'ruby-debug'

module Normalic
  module Address
    def self.parse(address)
      regex = {
        #:unit => /\W+(?:(?:su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|fl|floor|apt|apartment|unit|box)\W+|\#\W*)[\w-]+/i,
        :unit => /(((\#?\w*)?\W*(su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box))$)|(\W((su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box)\W*(\#?\w*)?)\W{0,3}$)/i,
        #:unit => /\W+(?:floor\W+|\#\W*)[\w-]+,?/i,
        :direct => Regexp.new(Directional.keys * '|' + '|' + Directional.values * '\.?|',Regexp::IGNORECASE),
        #:direct => /west/i,
        :type => Regexp.new('(' + StreetTypes_list * '|' + ')\\W*?$',Regexp::IGNORECASE),
        #:type => /street\W$/i,
        :number => /\d+-?\d*/,
        :fraction => /\d+\/\d+/,
        :country => /\W+USA$/,
        :zipcode => /\W+(\d{5}|\d{5}-\d{4})$/,
        :state => Regexp.new('\W+(' + StateCodes.values * '|' + '|' + StateCodes.keys * '|' + ')$',Regexp::IGNORECASE),
      }
      regex[:street] = Regexp.new('((' + regex[:direct].source + ')\\W)?\\W*(.*)\\W*(' + regex[:type].source + ')?', Regexp::IGNORECASE)

      #get rid of USA at the end
      country_code = address[regex[:country]] and address.gsub!(regex[:country], "")
      zipcode = address[regex[:zipcode]] and address.gsub!(regex[:zipcode], "")
      zipcode.gsub!(/\W/, "") if zipcode

      state = address[regex[:state]] and address.gsub!(regex[:state], "")
      state.gsub!(/(^\W*|\W*$)/, "").downcase! if state
      state = StateCodes[state] || state and state.downcase!

      if ZipCityMap[zipcode]
        regex[:city] = Regexp.new("\\W+" + ZipCityMap[zipcode] + "$", Regexp::IGNORECASE)
        regex[:city] = /,.*$/ if !address[regex[:city]]
        city = ZipCityMap[zipcode]
      else
        regex[:city] = /,.*$/
        city = address[regex[:city]] 
        city.gsub!(/(^\W*|\W*$)/, "").downcase! if city
      end

      address.gsub!(regex[:city], "")
      #address.gsub!(Regexp.new('\W(' + regex[:unit].source + ')\\W{0,3}$', Regexp::IGNORECASE), "")
      address.gsub!(regex[:unit], "")
      address.gsub!(Regexp.new('\W(' + regex[:direct].source + ')\\W{0,3}$', Regexp::IGNORECASE), "")
      type = address[regex[:type]] and address.gsub!(regex[:type], "")
      type.gsub!(/(^\W*|\W*$)/, "").downcase! if type
      type = StreetTypes[type] || type if type

      if address =~ /(\Wand\W|\W\&\W)/
        #intersections.  print as is
        address.gsub!(/(\Wand\W|\W\&\W)/, " and ")
        arr = ["", address, "", ""]
      else
        #regex[:address] = Regexp.new('^\W*(' + regex[:number].source + '\\W)?\W*(?:' + regex[:fraction].source + '\W*)?' + regex[:street].source + '\W*?(?:' + regex[:unit].source + '\W+)?(?:,)', Regexp::IGNORECASE)
        regex[:address] = Regexp.new('^\W*(' + regex[:number].source + '\\W)?\W*(?:' + regex[:fraction].source + '\W*)?' + regex[:street].source, Regexp::IGNORECASE)
        arr = regex[:address].match(address).to_a
      end

      number = arr[1].strip if arr[1]
      if arr[2] && (!arr[4] || arr[4].empty?)
        street = arr[2].strip.downcase
      else
        dir = Directional[arr[2].strip.downcase] || arr[2].strip.downcase if arr[2]
        dir.gsub!(/\W/, "") if dir
      end
      street = arr[4].strip.downcase if arr[4] && !street

      {
        :number => number,
        :direction => dir,
        :street => street,
        :type => type,
        :city => city,
        :state => state,
        :zipcode => zipcode
      }
      #addr = [number, dir, street, type].delete_if {|x| !x || x.empty?}
      #[addr.join(" "), city, state, zipcode].delete_if {|x| !x || x.empty?}.join(", ")
    end
  end
end