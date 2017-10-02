#encoding: utf-8
module Plugins::Ecommerce::EcommerceFunctionsHelper
  # return the visitor key which is used to relate the cart until login/register
  def ecommerce_get_visitor_key
    cookies[:e_cart_id] ||= cama_get_session_id unless cama_current_user.present?
  end

  # return the current cart for current user
  def e_current_cart(custom_visitor_key = nil)
    @_cache_e_current_cart ||= current_site.carts.set_user(custom_visitor_key || cama_current_user || ecommerce_get_visitor_key).active_cart.first_or_create(name: "Cart by #{Time.current.to_s}").decorate
  end

  # return all shipping country codes supported for shipping
  def e_shipping_countries
    current_site.e_settings[:shipping_countries] || ISO3166::Country.codes
  end

  # return (Array) all the currencies for visitors
  def e_visitor_unit_currencies
    current_site.e_settings[:visitor_unit_currencies] || ['USD']
  end

  # draw a select dropdown with all frontend currencies and actions to change current currency
  # long_mode: (Boolean, default false)
  # attrs = (Hash) attributes of the select drodown, sample: {class: 'form-control'}
  def e_draw_ecommerce_currencies(long_mode = false, attrs = {})
    return '' if e_visitor_unit_currencies.count <= 1
    res = '<select '+attrs.collect{|k, v| "#{k}='#{v}'" }.join(" ")+' onchange="window.location.href=window.location.href.split(\'cama_change_currency\')[0]+(window.location.href.search(\'\\\?\') > 1 ? \'&\' : \'?\')+\'cama_change_currency=\'+this.value">'
    e_visitor_unit_currencies.each do |unit|
      cur = e_get_currency_by_code(unit)
      res << "<option value='#{unit}' #{'selected' if e_current_visitor_currency == unit}>#{long_mode ? "#{cur[:label]} (#{cur[:symbol]})": cur[:symbol]}</option>"
    end
    res << '</select>'
  end

  # set a new currency if new_currency is present
  # return current currency defined by the current visitor
  def e_current_visitor_currency(new_currency = nil)
    session[:e_current_visitor_currency] = new_currency if new_currency.present?
    session[:e_current_visitor_currency] || 'USD'
  end

  # return all currency weights supported by the plugin
  def e_get_currency_weights
    @_cache_e_get_currency_weights ||= lambda{
      weights = {kg: t('plugins.ecommerce.select.kilogram'), lb: t('plugins.ecommerce.select.pound'), dr: t('plugins.ecommerce.select.dram'), gr: t('plugins.ecommerce.select.grain'), g: t('plugins.ecommerce.select.gram'), mg: t('plugins.ecommerce.select.milligram'), oz: t('plugins.ecommerce.select.ounce'), t: t('plugins.ecommerce.select.tonne'), UK: t('plugins.ecommerce.select.hundredweight')}
      hooks_run('ecommerce_weights', weights)
      weights
    }.call
  end

  # return the currency details with code = code
  def e_get_currency_by_code(code)
    e_get_all_currencies[code.to_s.upcase] || {}
  end

  # return the currency defined for admin panel
  def e_system_currency
    current_site.e_settings[:current_unit] || 'USD'
  end

  # render price formatted of a product with current currency
  def e_parse_price(price)
    currency = cama_is_admin_request? ? e_system_currency : e_current_visitor_currency
    args = {currency: currency, price: price, data: number_to_currency(e_parse_to_current_currency(price), unit: currency)}; hooks_run('ecommerce_parse_price', args) # permit to customize price format
    args[:data]
  end

  # convert the amount of system currency into visitor current currency
  # amount: (Number) which will be exchanged into current visitor's currency
  # return the modified amount (Integer)
  def e_parse_to_current_currency(amount)
    amount = amount.to_f
    args = {amount: amount, from: e_system_currency, to: e_current_visitor_currency, exchange: nil}
    return amount if cama_is_admin_request? || args[:from] == args[:to] || amount.to_f.round(2) == 0.00

    currency = cama_ecommerce_post_type.get_option(e_current_visitor_currency, {}, 'currencies')
    return (currency[:exchange] * amount).round(2) if currency[:date] == Date.today.to_s && currency[:base] == e_system_currency

    hooks_run('ecommerce_calculate_exchange', args) # permit to use custom exchange app by setting the value in :exchange attribute
    return (args[:exchange] * amount).round(2) if args[:exchange].present?

    exchange = e_finance_exchange_converter(args)
    cama_ecommerce_post_type.set_option(e_current_visitor_currency, {date: Date.today.to_s, exchange: exchange, base: e_system_currency}, 'currencies')
    (exchange * amount).round(2)
  end

  # helper to calculate exchanges
  def e_finance_exchange_converter(args)
    # request to google's finance converter site
    res = open("https://finance.google.com/finance/converter?a=1&from=#{args[:from]}&to=#{args[:to]}").read
    res = res.scan(/\<span class=bld\>(.+?)\<\/span\>/).first.first.split(' ') # => ["69.3000", "BOB"]
    res.first.to_f.round(4)
  end

  # return all currencies to use as a base currency
  def e_get_all_currencies
    @_cache_e_get_all_currencies ||= lambda{
      currencies = {
        'AED' => {symbol: 'AED', label: t('plugins.ecommerce.currencies.aed', default: 'United Arab Emirates Dirham')},
        'AFN' => {symbol: 'AFN', label: t('plugins.ecommerce.currencies.afn', default: 'Afghan Afghani')},
        'ALL' => {symbol: 'ALL', label: t('plugins.ecommerce.currencies.all', default: 'Albanian Lek')},
        'AMD' => {symbol: 'AMD', label: t('plugins.ecommerce.currencies.amd', default: 'Armenian Dram')},
        'ANG' => {symbol: 'ANG', label: t('plugins.ecommerce.currencies.ang', default: 'Netherlands Antillean Guilder')},
        'AOA' => {symbol: 'AOA', label: t('plugins.ecommerce.currencies.aoa', default: 'Angolan Kwanza')},
        'ARS' => {symbol: 'ARS', label: t('plugins.ecommerce.currencies.ars', default: 'Argentine Peso')},
        'AUD' => {symbol: 'A$', label: t('plugins.ecommerce.currencies.aud', default: 'Australian Dollar')},
        'AWG' => {symbol: 'AWG', label: t('plugins.ecommerce.currencies.awg', default: 'Aruban Florin')},
        'AZN' => {symbol: 'AZN', label: t('plugins.ecommerce.currencies.azn', default: 'Azerbaijani Manat')},
        'BAM' => {symbol: 'BAM', label: t('plugins.ecommerce.currencies.bam', default: 'Bosnia-Herzegovina Convertible Mark')},
        'BBD' => {symbol: 'BBD', label: t('plugins.ecommerce.currencies.bbd', default: 'Barbadian Dollar')},
        'BDT' => {symbol: 'BDT', label: t('plugins.ecommerce.currencies.bdt', default: 'Bangladeshi Taka')},
        'BGN' => {symbol: 'BGN', label: t('plugins.ecommerce.currencies.bgn', default: 'Bulgarian Lev')},
        'BHD' => {symbol: 'BHD', label: t('plugins.ecommerce.currencies.bhd', default: 'Bahraini Dinar')},
        'BIF' => {symbol: 'BIF', label: t('plugins.ecommerce.currencies.bif', default: 'Burundian Franc')},
        'BMD' => {symbol: 'BMD', label: t('plugins.ecommerce.currencies.bmd', default: 'Bermudan Dollar')},
        'BND' => {symbol: 'BND', label: t('plugins.ecommerce.currencies.bnd', default: 'Brunei Dollar')},
        'BOB' => {symbol: 'BOB', label: t('plugins.ecommerce.currencies.bob', default: 'Bolivian Boliviano')},
        'BRL' => {symbol: 'R$', label: t('plugins.ecommerce.currencies.brl', default: 'Brazilian Real')},
        'BSD' => {symbol: 'BSD', label: t('plugins.ecommerce.currencies.bsd', default: 'Bahamian Dollar')},
        'BTC' => {symbol: '฿', label: t('plugins.ecommerce.currencies.btc', default: 'Bitcoin')},
        'BTN' => {symbol: 'BTN', label: t('plugins.ecommerce.currencies.btn', default: 'Bhutanese Ngultrum')},
        'BWP' => {symbol: 'BWP', label: t('plugins.ecommerce.currencies.bwp', default: 'Botswanan Pula')},
        'BYN' => {symbol: 'BYN', label: t('plugins.ecommerce.currencies.byn', default: 'Belarusian Ruble')},
        'BYR' => {symbol: '2000-2016 ', label: t('plugins.ecommerce.currencies.byr', default: 'Belarusian Ruble')},
        'BZD' => {symbol: 'BZD', label: t('plugins.ecommerce.currencies.bzd', default: 'Belize Dollar')},
        'CAD' => {symbol: 'CA$', label: t('plugins.ecommerce.currencies.cad', default: 'Canadian Dollar')},
        'CDF' => {symbol: 'CDF', label: t('plugins.ecommerce.currencies.cdf', default: 'Congolese Franc')},
        'CHF' => {symbol: 'CHF', label: t('plugins.ecommerce.currencies.chf', default: 'Swiss Franc')},
        'CLF' => {symbol: 'UF ', label: t('plugins.ecommerce.currencies.clf', default: 'Chilean Unit of Account')},
        'CLP' => {symbol: 'CLP', label: t('plugins.ecommerce.currencies.clp', default: 'Chilean Peso')},
        'CNH' => {symbol: 'CNH', label: t('plugins.ecommerce.currencies.cnh', default: 'CNH')},
        'CNY' => {symbol: 'CN¥', label: t('plugins.ecommerce.currencies.cny', default: 'Chinese Yuan')},
        'COP' => {symbol: 'COP', label: t('plugins.ecommerce.currencies.cop', default: 'Colombian Peso')},
        'CRC' => {symbol: 'CRC', label: t('plugins.ecommerce.currencies.crc', default: 'Costa Rican Colón')},
        'CUP' => {symbol: 'CUP', label: t('plugins.ecommerce.currencies.cup', default: 'Cuban Peso')},
        'CVE' => {symbol: 'CVE', label: t('plugins.ecommerce.currencies.cve', default: 'Cape Verdean Escudo')},
        'CZK' => {symbol: 'CZK', label: t('plugins.ecommerce.currencies.czk', default: 'Czech Republic Koruna')},
        'DEM' => {symbol: 'DEM', label: t('plugins.ecommerce.currencies.dem', default: 'German Mark')},
        'DJF' => {symbol: 'DJF', label: t('plugins.ecommerce.currencies.djf', default: 'Djiboutian Franc')},
        'DKK' => {symbol: 'DKK', label: t('plugins.ecommerce.currencies.dkk', default: 'Danish Krone')},
        'DOP' => {symbol: 'DOP', label: t('plugins.ecommerce.currencies.dop', default: 'Dominican Peso')},
        'DZD' => {symbol: 'DZD', label: t('plugins.ecommerce.currencies.dzd', default: 'Algerian Dinar')},
        'EGP' => {symbol: 'EGP', label: t('plugins.ecommerce.currencies.egp', default: 'Egyptian Pound')},
        'ERN' => {symbol: 'ERN', label: t('plugins.ecommerce.currencies.ern', default: 'Eritrean Nakfa')},
        'ETB' => {symbol: 'ETB', label: t('plugins.ecommerce.currencies.etb', default: 'Ethiopian Birr')},
        'EUR' => {symbol: '€', label: t('plugins.ecommerce.currencies.eur', default: 'Euro')},
        'FIM' => {symbol: 'FIM', label: t('plugins.ecommerce.currencies.fim', default: 'Finnish Markka')},
        'FJD' => {symbol: 'FJD', label: t('plugins.ecommerce.currencies.fjd', default: 'Fijian Dollar')},
        'FKP' => {symbol: 'FKP', label: t('plugins.ecommerce.currencies.fkp', default: 'Falkland Islands Pound')},
        'FRF' => {symbol: 'FRF', label: t('plugins.ecommerce.currencies.frf', default: 'French Franc')},
        'GBP' => {symbol: '£', label: t('plugins.ecommerce.currencies.gbp', default: 'British Pound')},
        'GEL' => {symbol: 'GEL', label: t('plugins.ecommerce.currencies.gel', default: 'Georgian Lari')},
        'GHS' => {symbol: 'GHS', label: t('plugins.ecommerce.currencies.ghs', default: 'Ghanaian Cedi')},
        'GIP' => {symbol: 'GIP', label: t('plugins.ecommerce.currencies.gip', default: 'Gibraltar Pound')},
        'GMD' => {symbol: 'GMD', label: t('plugins.ecommerce.currencies.gmd', default: 'Gambian Dalasi')},
        'GNF' => {symbol: 'GNF', label: t('plugins.ecommerce.currencies.gnf', default: 'Guinean Franc')},
        'GTQ' => {symbol: 'GTQ', label: t('plugins.ecommerce.currencies.gtq', default: 'Guatemalan Quetzal')},
        'GYD' => {symbol: 'GYD', label: t('plugins.ecommerce.currencies.gyd', default: 'Guyanaese Dollar')},
        'HKD' => {symbol: 'HK$', label: t('plugins.ecommerce.currencies.hkd', default: 'Hong Kong Dollar')},
        'HNL' => {symbol: 'HNL', label: t('plugins.ecommerce.currencies.hnl', default: 'Honduran Lempira')},
        'HRK' => {symbol: 'HRK', label: t('plugins.ecommerce.currencies.hrk', default: 'Croatian Kuna')},
        'HTG' => {symbol: 'HTG', label: t('plugins.ecommerce.currencies.htg', default: 'Haitian Gourde')},
        'HUF' => {symbol: 'HUF', label: t('plugins.ecommerce.currencies.huf', default: 'Hungarian Forint')},
        'IDR' => {symbol: 'IDR', label: t('plugins.ecommerce.currencies.idr', default: 'Indonesian Rupiah')},
        'IEP' => {symbol: 'IEP', label: t('plugins.ecommerce.currencies.iep', default: 'Irish Pound')},
        'ILS' => {symbol: '₪', label: t('plugins.ecommerce.currencies.ils', default: 'Israeli New Sheqel')},
        'INR' => {symbol: '₹', label: t('plugins.ecommerce.currencies.inr', default: 'Indian Rupee')},
        'IQD' => {symbol: 'IQD', label: t('plugins.ecommerce.currencies.iqd', default: 'Iraqi Dinar')},
        'IRR' => {symbol: 'IRR', label: t('plugins.ecommerce.currencies.irr', default: 'Iranian Rial')},
        'ISK' => {symbol: 'ISK', label: t('plugins.ecommerce.currencies.isk', default: 'Icelandic Króna')},
        'ITL' => {symbol: 'ITL', label: t('plugins.ecommerce.currencies.itl', default: 'Italian Lira')},
        'JMD' => {symbol: 'JMD', label: t('plugins.ecommerce.currencies.jmd', default: 'Jamaican Dollar')},
        'JOD' => {symbol: 'JOD', label: t('plugins.ecommerce.currencies.jod', default: 'Jordanian Dinar')},
        'JPY' => {symbol: '¥', label: t('plugins.ecommerce.currencies.jpy', default: 'Japanese Yen')},
        'KES' => {symbol: 'KES', label: t('plugins.ecommerce.currencies.kes', default: 'Kenyan Shilling')},
        'KGS' => {symbol: 'KGS', label: t('plugins.ecommerce.currencies.kgs', default: 'Kyrgystani Som')},
        'KHR' => {symbol: 'KHR', label: t('plugins.ecommerce.currencies.khr', default: 'Cambodian Riel')},
        'KMF' => {symbol: 'KMF', label: t('plugins.ecommerce.currencies.kmf', default: 'Comorian Franc')},
        'KPW' => {symbol: 'KPW', label: t('plugins.ecommerce.currencies.kpw', default: 'North Korean Won')},
        'KRW' => {symbol: '₩', label: t('plugins.ecommerce.currencies.krw', default: 'South Korean Won')},
        'KWD' => {symbol: 'KWD', label: t('plugins.ecommerce.currencies.kwd', default: 'Kuwaiti Dinar')},
        'KYD' => {symbol: 'KYD', label: t('plugins.ecommerce.currencies.kyd', default: 'Cayman Islands Dollar')},
        'KZT' => {symbol: 'KZT', label: t('plugins.ecommerce.currencies.kzt', default: 'Kazakhstani Tenge')},
        'LAK' => {symbol: 'LAK', label: t('plugins.ecommerce.currencies.lak', default: 'Laotian Kip')},
        'LBP' => {symbol: 'LBP', label: t('plugins.ecommerce.currencies.lbp', default: 'Lebanese Pound')},
        'LKR' => {symbol: 'LKR', label: t('plugins.ecommerce.currencies.lkr', default: 'Sri Lankan Rupee')},
        'LRD' => {symbol: 'LRD', label: t('plugins.ecommerce.currencies.lrd', default: 'Liberian Dollar')},
        'LSL' => {symbol: 'LSL', label: t('plugins.ecommerce.currencies.lsl', default: 'Lesotho Loti')},
        'LTL' => {symbol: 'LTL', label: t('plugins.ecommerce.currencies.ltl', default: 'Lithuanian Litas')},
        'LVL' => {symbol: 'LVL', label: t('plugins.ecommerce.currencies.lvl', default: 'Latvian Lats')},
        'LYD' => {symbol: 'LYD', label: t('plugins.ecommerce.currencies.lyd', default: 'Libyan Dinar')},
        'MAD' => {symbol: 'MAD', label: t('plugins.ecommerce.currencies.mad', default: 'Moroccan Dirham')},
        'MDL' => {symbol: 'MDL', label: t('plugins.ecommerce.currencies.mdl', default: 'Moldovan Leu')},
        'MGA' => {symbol: 'MGA', label: t('plugins.ecommerce.currencies.mga', default: 'Malagasy Ariary')},
        'MKD' => {symbol: 'MKD', label: t('plugins.ecommerce.currencies.mkd', default: 'Macedonian Denar')},
        'MMK' => {symbol: 'MMK', label: t('plugins.ecommerce.currencies.mmk', default: 'Myanmar Kyat')},
        'MNT' => {symbol: 'MNT', label: t('plugins.ecommerce.currencies.mnt', default: 'Mongolian Tugrik')},
        'MOP' => {symbol: 'MOP', label: t('plugins.ecommerce.currencies.mop', default: 'Macanese Pataca')},
        'MRO' => {symbol: 'MRO', label: t('plugins.ecommerce.currencies.mro', default: 'Mauritanian Ouguiya')},
        'MUR' => {symbol: 'MUR', label: t('plugins.ecommerce.currencies.mur', default: 'Mauritian Rupee')},
        'MVR' => {symbol: 'MVR', label: t('plugins.ecommerce.currencies.mvr', default: 'Maldivian Rufiyaa')},
        'MWK' => {symbol: 'MWK', label: t('plugins.ecommerce.currencies.mwk', default: 'Malawian Kwacha')},
        'MXN' => {symbol: 'MX$', label: t('plugins.ecommerce.currencies.mxn', default: 'Mexican Peso')},
        'MYR' => {symbol: 'MYR', label: t('plugins.ecommerce.currencies.myr', default: 'Malaysian Ringgit')},
        'MZN' => {symbol: 'MZN', label: t('plugins.ecommerce.currencies.mzn', default: 'Mozambican Metical')},
        'NAD' => {symbol: 'NAD', label: t('plugins.ecommerce.currencies.nad', default: 'Namibian Dollar')},
        'NGN' => {symbol: 'NGN', label: t('plugins.ecommerce.currencies.ngn', default: 'Nigerian Naira')},
        'NIO' => {symbol: 'NIO', label: t('plugins.ecommerce.currencies.nio', default: 'Nicaraguan Córdoba')},
        'NOK' => {symbol: 'NOK', label: t('plugins.ecommerce.currencies.nok', default: 'Norwegian Krone')},
        'NPR' => {symbol: 'NPR', label: t('plugins.ecommerce.currencies.npr', default: 'Nepalese Rupee')},
        'NZD' => {symbol: 'NZ$', label: t('plugins.ecommerce.currencies.nzd', default: 'New Zealand Dollar')},
        'OMR' => {symbol: 'OMR', label: t('plugins.ecommerce.currencies.omr', default: 'Omani Rial')},
        'PAB' => {symbol: 'PAB', label: t('plugins.ecommerce.currencies.pab', default: 'Panamanian Balboa')},
        'PEN' => {symbol: 'PEN', label: t('plugins.ecommerce.currencies.pen', default: 'Peruvian Nuevo Sol')},
        'PGK' => {symbol: 'PGK', label: t('plugins.ecommerce.currencies.pgk', default: 'Papua New Guinean Kina')},
        'PHP' => {symbol: 'PHP', label: t('plugins.ecommerce.currencies.php', default: 'Philippine Peso')},
        'PKG' => {symbol: 'PKG', label: t('plugins.ecommerce.currencies.pkg', default: 'PKG')},
        'PKR' => {symbol: 'PKR', label: t('plugins.ecommerce.currencies.pkr', default: 'Pakistani Rupee')},
        'PLN' => {symbol: 'PLN', label: t('plugins.ecommerce.currencies.pln', default: 'Polish Zloty')},
        'PYG' => {symbol: 'PYG', label: t('plugins.ecommerce.currencies.pyg', default: 'Paraguayan Guarani')},
        'QAR' => {symbol: 'QAR', label: t('plugins.ecommerce.currencies.qar', default: 'Qatari Rial')},
        'RON' => {symbol: 'RON', label: t('plugins.ecommerce.currencies.ron', default: 'Romanian Leu')},
        'RSD' => {symbol: 'RSD', label: t('plugins.ecommerce.currencies.rsd', default: 'Serbian Dinar')},
        'RUB' => {symbol: 'RUB', label: t('plugins.ecommerce.currencies.rub', default: 'Russian Ruble')},
        'RWF' => {symbol: 'RWF', label: t('plugins.ecommerce.currencies.rwf', default: 'Rwandan Franc')},
        'SAR' => {symbol: 'SAR', label: t('plugins.ecommerce.currencies.sar', default: 'Saudi Riyal')},
        'SBD' => {symbol: 'SBD', label: t('plugins.ecommerce.currencies.sbd', default: 'Solomon Islands Dollar')},
        'SCR' => {symbol: 'SCR', label: t('plugins.ecommerce.currencies.scr', default: 'Seychellois Rupee')},
        'SDG' => {symbol: 'SDG', label: t('plugins.ecommerce.currencies.sdg', default: 'Sudanese Pound')},
        'SEK' => {symbol: 'SEK', label: t('plugins.ecommerce.currencies.sek', default: 'Swedish Krona')},
        'SGD' => {symbol: 'SGD', label: t('plugins.ecommerce.currencies.sgd', default: 'Singapore Dollar')},
        'SHP' => {symbol: 'SHP', label: t('plugins.ecommerce.currencies.shp', default: 'St. Helena Pound')},
        'SKK' => {symbol: 'SKK', label: t('plugins.ecommerce.currencies.skk', default: 'Slovak Koruna')},
        'SLL' => {symbol: 'SLL', label: t('plugins.ecommerce.currencies.sll', default: 'Sierra Leonean Leone')},
        'SOS' => {symbol: 'SOS', label: t('plugins.ecommerce.currencies.sos', default: 'Somali Shilling')},
        'SRD' => {symbol: 'SRD', label: t('plugins.ecommerce.currencies.srd', default: 'Surinamese Dollar')},
        'STD' => {symbol: 'STD', label: t('plugins.ecommerce.currencies.std', default: 'São Tomé & Príncipe Dobra')},
        'SVC' => {symbol: 'SVC', label: t('plugins.ecommerce.currencies.svc', default: 'Salvadoran Colón')},
        'SYP' => {symbol: 'SYP', label: t('plugins.ecommerce.currencies.syp', default: 'Syrian Pound')},
        'SZL' => {symbol: 'SZL', label: t('plugins.ecommerce.currencies.szl', default: 'Swazi Lilangeni')},
        'THB' => {symbol: 'THB', label: t('plugins.ecommerce.currencies.thb', default: 'Thai Baht')},
        'TJS' => {symbol: 'TJS', label: t('plugins.ecommerce.currencies.tjs', default: 'Tajikistani Somoni')},
        'TMT' => {symbol: 'TMT', label: t('plugins.ecommerce.currencies.tmt', default: 'Turkmenistani Manat')},
        'TND' => {symbol: 'TND', label: t('plugins.ecommerce.currencies.tnd', default: 'Tunisian Dinar')},
        'TOP' => {symbol: 'TOP', label: t('plugins.ecommerce.currencies.top', default: 'Tongan Paʻanga')},
        'TRY' => {symbol: 'TRY', label: t('plugins.ecommerce.currencies.try', default: 'Turkish Lira')},
        'TTD' => {symbol: 'TTD', label: t('plugins.ecommerce.currencies.ttd', default: 'Trinidad & Tobago Dollar')},
        'TWD' => {symbol: 'NT$', label: t('plugins.ecommerce.currencies.twd', default: 'New Taiwan Dollar')},
        'TZS' => {symbol: 'TZS', label: t('plugins.ecommerce.currencies.tzs', default: 'Tanzanian Shilling')},
        'UAH' => {symbol: 'UAH', label: t('plugins.ecommerce.currencies.uah', default: 'Ukrainian Hryvnia')},
        'UGX' => {symbol: 'UGX', label: t('plugins.ecommerce.currencies.ugx', default: 'Ugandan Shilling')},
        'USD' => {symbol: '$', label: t('plugins.ecommerce.currencies.usd', default: 'US Dollar')},
        'UYU' => {symbol: 'UYU', label: t('plugins.ecommerce.currencies.uyu', default: 'Uruguayan Peso')},
        'UZS' => {symbol: 'UZS', label: t('plugins.ecommerce.currencies.uzs', default: 'Uzbekistani Som')},
        'VEF' => {symbol: 'VEF', label: t('plugins.ecommerce.currencies.vef', default: 'Venezuelan Bolívar')},
        'VND' => {symbol: '₫', label: t('plugins.ecommerce.currencies.vnd', default: 'Vietnamese Dong')},
        'VUV' => {symbol: 'VUV', label: t('plugins.ecommerce.currencies.vuv', default: 'Vanuatu Vatu')},
        'WST' => {symbol: 'WST', label: t('plugins.ecommerce.currencies.wst', default: 'Samoan Tala')},
        'XAF' => {symbol: 'FCFA', label: t('plugins.ecommerce.currencies.xaf', default: 'Central African CFA Franc')},
        'XCD' => {symbol: 'EC$', label: t('plugins.ecommerce.currencies.xcd', default: 'East Caribbean Dollar')},
        'XDR' => {symbol: 'XDR', label: t('plugins.ecommerce.currencies.xdr', default: 'Special Drawing Rights')},
        'XOF' => {symbol: 'CFA', label: t('plugins.ecommerce.currencies.xof', default: 'West African CFA Franc')},
        'XPF' => {symbol: 'CFPF', label: t('plugins.ecommerce.currencies.xpf', default: 'CFP Franc')},
        'YER' => {symbol: 'YER', label: t('plugins.ecommerce.currencies.yer', default: 'Yemeni Rial')},
        'ZAR' => {symbol: 'ZAR', label: t('plugins.ecommerce.currencies.zar', default: 'South African Rand')},
        'ZMK' => {symbol: '1968–2012 ', label: t('plugins.ecommerce.currencies.zmk', default: 'Zambian Kwacha')},
        'ZMW' => {symbol: 'ZMW', label: t('plugins.ecommerce.currencies.zmw', default: 'Zambian Kwacha')},
        'ZWL' => {symbol: '2009 ', label: t('plugins.ecommerce.currencies.zwl', default: 'Zimbabwean Dollar')}
      }
      hooks_run('ecommerce_currencies', currencies)
      currencies
    }.call
  end

  def ecommerce_draw_breadcrumb
    res = '<ol class="breadcrumb" style="margin: 0;">'
    (@ecommerce_breadcrumb || []).each_with_index do |m, index|
      if m[1].present?
        res << "<li class='#{"active" if @ecommerce_breadcrumb.size == index+1}'><a href='#{m[1]}'>#{m[0]}</a></li>"
      else
        res << "<li class='#{"active" if @ecommerce_breadcrumb.size == index+1}'><span>#{m[0]}</span></li>"
      end
    end
    res << '</ol>'
  end

  # permit to add custom payment methods by hooks
  def ecommerce_custom_payment_methods
    @_ecommerce_custom_payment_methods ||= lambda{
      args = {custom_payment_methods: {}}; hooks_run("ecommerce_custom_payment_methods", args)
      # Sample:
      # def my_callback(args)
      #   args[:custom_payment_methods][:pay_u] = {
          # title: 'Pay U',
          # settings_view_path: '/my_plugin/views/payu/settings', # view must be like this: <div class="form-group"> <label>Key</label><br> <%= text_field_tag('options[payu_key]', options[:payu_key], class: 'form-control required') %> </div>
          # payment_form_view_path: '/my_plugin/views/payu/payment_form',
            # # view must include the payment form with your custom routes to process the payment,
            # # sample: https://github.com/owen2345/camaleon-ecommerce/blob/master/app/controllers/plugins/ecommerce/front/checkout_controller.rb#L120
            # #         https://github.com/owen2345/camaleon-ecommerce/blob/master/app/views/plugins/ecommerce/partials/checkout/_payments.html.erb#L104
      #   }
      # end
      args[:custom_payment_methods]
    }.call
  end
end
