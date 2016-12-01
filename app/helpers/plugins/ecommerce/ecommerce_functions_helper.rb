#encoding: utf-8
module Plugins::Ecommerce::EcommerceFunctionsHelper
  # convert money into cents
  def commerce_to_cents(money)
    Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(money)
  end

  # return the settings for ecommerce (Hash)
  def ecommerce_get_settings
    current_site.get_meta("_setting_ecommerce", {})
  end

  # draw a select dropdown with all frontend currencies and actions to change current currency
  # mode: long | short
  def e_draw_ecommerce_currencies(mode = 'long')
    return '' if ecommerce_get_settings[:visitor_unit_currencies].count <= 1
    res = '<select onchange="window.location.href=window.location.href.split(\'cama_change_currency\')[0]+(window.location.href.search(\'\\\?\') > 1 ? \'&\' : \'?\')+\'cama_change_currency=\'+this.value">'
    ecommerce_get_settings[:visitor_unit_currencies].each do |unit|
      cur = e_get_currency_by_code(unit)
      res << "<option value='#{unit}' #{'selected' if e_current_visitor_currency == unit}>#{mode == 'long' ? "#{cur[:label]} (#{cur[:symbol]})": cur[:symbol]}</option>"
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
  def e_get_currency_weight
    @_cache_e_get_currency_weight ||= lambda{
      weights = {kg: t('plugin.ecommerce.select.kilogram'), lb: t('plugin.ecommerce.select.pound'), dr: t('plugin.ecommerce.select.dram'), gr: t('plugin.ecommerce.select.grain'), g: t('plugin.ecommerce.select.gram'), mg: t('plugin.ecommerce.select.milligram'), oz: t('plugin.ecommerce.select.ounce'), t: t('plugin.ecommerce.select.tonne'), UK: t('plugin.ecommerce.select.hundredweight')}
      hooks_run('ecommerce_weights', weights)
      weights
    }.call
  end

  # return the currency details with code = code
  def e_get_currency_by_code(code)
    e_get_currency_units[code.to_s.upcase] || {}
  end

  # return the currency defined for admin panel
  def e_system_currency
    ecommerce_get_settings[:current_unit] || 'USD'
  end

  # render price formatted of a product with current currency
  def e_parse_price(price)
    currency = cama_is_admin_request? ? e_system_currency : e_current_visitor_currency
    args = {currency: currency, price: price, data: "#{currency} #{sprintf('%.2f', e_parse_to_current_currency(price))}"}; hooks_run('ecommerce_parse_price', args) # permit to customize price format
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
    return (currency[:exchange] * amount).round(2) if currency[:date] == Date.today.to_s

    hooks_run('ecommerce_calculate_exchange', args) # permit to use custom exchange app by setting the value in :exchange attribute
    return (args[:exchange] * amount).round(2) if args[:exchange].present?

    # request to google's finance converter site
    res = open("https://www.google.com/finance/converter?a=1&from=#{args[:from]}&to=#{args[:to]}").read
    res = res.scan(/\<span class=bld\>(.+?)\<\/span\>/).first.first.split(' ') # => ["69.3000", "BOB"]
    exchange = res.first.to_f.round(4)
    cama_ecommerce_post_type.set_option(e_current_visitor_currency, {date: Date.today.to_s, exchange: exchange}, 'currencies')
    (exchange * amount).round(2)
  end

  # return all currencies to use as a base currency
  def e_get_currency_units
    @_cache_e_get_currency_units ||= lambda{
      currencies = {
        'AED' => {symbol: 'AED', label: t('plugin.ecommerce.currencies.aed', default: 'United Arab Emirates Dirham')},
        'AFN' => {symbol: 'AFN', label: t('plugin.ecommerce.currencies.afn', default: 'Afghan Afghani')},
        'ALL' => {symbol: 'ALL', label: t('plugin.ecommerce.currencies.all', default: 'Albanian Lek')},
        'AMD' => {symbol: 'AMD', label: t('plugin.ecommerce.currencies.amd', default: 'Armenian Dram')},
        'ANG' => {symbol: 'ANG', label: t('plugin.ecommerce.currencies.ang', default: 'Netherlands Antillean Guilder')},
        'AOA' => {symbol: 'AOA', label: t('plugin.ecommerce.currencies.aoa', default: 'Angolan Kwanza')},
        'ARS' => {symbol: 'ARS', label: t('plugin.ecommerce.currencies.ars', default: 'Argentine Peso')},
        'AUD' => {symbol: 'A$', label: t('plugin.ecommerce.currencies.aud', default: 'Australian Dollar')},
        'AWG' => {symbol: 'AWG', label: t('plugin.ecommerce.currencies.awg', default: 'Aruban Florin')},
        'AZN' => {symbol: 'AZN', label: t('plugin.ecommerce.currencies.azn', default: 'Azerbaijani Manat')},
        'BAM' => {symbol: 'BAM', label: t('plugin.ecommerce.currencies.bam', default: 'Bosnia-Herzegovina Convertible Mark')},
        'BBD' => {symbol: 'BBD', label: t('plugin.ecommerce.currencies.bbd', default: 'Barbadian Dollar')},
        'BDT' => {symbol: 'BDT', label: t('plugin.ecommerce.currencies.bdt', default: 'Bangladeshi Taka')},
        'BGN' => {symbol: 'BGN', label: t('plugin.ecommerce.currencies.bgn', default: 'Bulgarian Lev')},
        'BHD' => {symbol: 'BHD', label: t('plugin.ecommerce.currencies.bhd', default: 'Bahraini Dinar')},
        'BIF' => {symbol: 'BIF', label: t('plugin.ecommerce.currencies.bif', default: 'Burundian Franc')},
        'BMD' => {symbol: 'BMD', label: t('plugin.ecommerce.currencies.bmd', default: 'Bermudan Dollar')},
        'BND' => {symbol: 'BND', label: t('plugin.ecommerce.currencies.bnd', default: 'Brunei Dollar')},
        'BOB' => {symbol: 'BOB', label: t('plugin.ecommerce.currencies.bob', default: 'Bolivian Boliviano')},
        'BRL' => {symbol: 'R$', label: t('plugin.ecommerce.currencies.brl', default: 'Brazilian Real')},
        'BSD' => {symbol: 'BSD', label: t('plugin.ecommerce.currencies.bsd', default: 'Bahamian Dollar')},
        'BTC' => {symbol: '฿', label: t('plugin.ecommerce.currencies.btc', default: 'Bitcoin')},
        'BTN' => {symbol: 'BTN', label: t('plugin.ecommerce.currencies.btn', default: 'Bhutanese Ngultrum')},
        'BWP' => {symbol: 'BWP', label: t('plugin.ecommerce.currencies.bwp', default: 'Botswanan Pula')},
        'BYN' => {symbol: 'BYN', label: t('plugin.ecommerce.currencies.byn', default: 'Belarusian Ruble')},
        'BYR' => {symbol: '2000-2016 ', label: t('plugin.ecommerce.currencies.byr', default: 'Belarusian Ruble')},
        'BZD' => {symbol: 'BZD', label: t('plugin.ecommerce.currencies.bzd', default: 'Belize Dollar')},
        'CAD' => {symbol: 'CA$', label: t('plugin.ecommerce.currencies.cad', default: 'Canadian Dollar')},
        'CDF' => {symbol: 'CDF', label: t('plugin.ecommerce.currencies.cdf', default: 'Congolese Franc')},
        'CHF' => {symbol: 'CHF', label: t('plugin.ecommerce.currencies.chf', default: 'Swiss Franc')},
        'CLF' => {symbol: 'UF ', label: t('plugin.ecommerce.currencies.clf', default: 'Chilean Unit of Account')},
        'CLP' => {symbol: 'CLP', label: t('plugin.ecommerce.currencies.clp', default: 'Chilean Peso')},
        'CNH' => {symbol: 'CNH', label: t('plugin.ecommerce.currencies.cnh', default: 'CNH')},
        'CNY' => {symbol: 'CN¥', label: t('plugin.ecommerce.currencies.cny', default: 'Chinese Yuan')},
        'COP' => {symbol: 'COP', label: t('plugin.ecommerce.currencies.cop', default: 'Colombian Peso')},
        'CRC' => {symbol: 'CRC', label: t('plugin.ecommerce.currencies.crc', default: 'Costa Rican Colón')},
        'CUP' => {symbol: 'CUP', label: t('plugin.ecommerce.currencies.cup', default: 'Cuban Peso')},
        'CVE' => {symbol: 'CVE', label: t('plugin.ecommerce.currencies.cve', default: 'Cape Verdean Escudo')},
        'CZK' => {symbol: 'CZK', label: t('plugin.ecommerce.currencies.czk', default: 'Czech Republic Koruna')},
        'DEM' => {symbol: 'DEM', label: t('plugin.ecommerce.currencies.dem', default: 'German Mark')},
        'DJF' => {symbol: 'DJF', label: t('plugin.ecommerce.currencies.djf', default: 'Djiboutian Franc')},
        'DKK' => {symbol: 'DKK', label: t('plugin.ecommerce.currencies.dkk', default: 'Danish Krone')},
        'DOP' => {symbol: 'DOP', label: t('plugin.ecommerce.currencies.dop', default: 'Dominican Peso')},
        'DZD' => {symbol: 'DZD', label: t('plugin.ecommerce.currencies.dzd', default: 'Algerian Dinar')},
        'EGP' => {symbol: 'EGP', label: t('plugin.ecommerce.currencies.egp', default: 'Egyptian Pound')},
        'ERN' => {symbol: 'ERN', label: t('plugin.ecommerce.currencies.ern', default: 'Eritrean Nakfa')},
        'ETB' => {symbol: 'ETB', label: t('plugin.ecommerce.currencies.etb', default: 'Ethiopian Birr')},
        'EUR' => {symbol: '€', label: t('plugin.ecommerce.currencies.eur', default: 'Euro')},
        'FIM' => {symbol: 'FIM', label: t('plugin.ecommerce.currencies.fim', default: 'Finnish Markka')},
        'FJD' => {symbol: 'FJD', label: t('plugin.ecommerce.currencies.fjd', default: 'Fijian Dollar')},
        'FKP' => {symbol: 'FKP', label: t('plugin.ecommerce.currencies.fkp', default: 'Falkland Islands Pound')},
        'FRF' => {symbol: 'FRF', label: t('plugin.ecommerce.currencies.frf', default: 'French Franc')},
        'GBP' => {symbol: '£', label: t('plugin.ecommerce.currencies.gbp', default: 'British Pound')},
        'GEL' => {symbol: 'GEL', label: t('plugin.ecommerce.currencies.gel', default: 'Georgian Lari')},
        'GHS' => {symbol: 'GHS', label: t('plugin.ecommerce.currencies.ghs', default: 'Ghanaian Cedi')},
        'GIP' => {symbol: 'GIP', label: t('plugin.ecommerce.currencies.gip', default: 'Gibraltar Pound')},
        'GMD' => {symbol: 'GMD', label: t('plugin.ecommerce.currencies.gmd', default: 'Gambian Dalasi')},
        'GNF' => {symbol: 'GNF', label: t('plugin.ecommerce.currencies.gnf', default: 'Guinean Franc')},
        'GTQ' => {symbol: 'GTQ', label: t('plugin.ecommerce.currencies.gtq', default: 'Guatemalan Quetzal')},
        'GYD' => {symbol: 'GYD', label: t('plugin.ecommerce.currencies.gyd', default: 'Guyanaese Dollar')},
        'HKD' => {symbol: 'HK$', label: t('plugin.ecommerce.currencies.hkd', default: 'Hong Kong Dollar')},
        'HNL' => {symbol: 'HNL', label: t('plugin.ecommerce.currencies.hnl', default: 'Honduran Lempira')},
        'HRK' => {symbol: 'HRK', label: t('plugin.ecommerce.currencies.hrk', default: 'Croatian Kuna')},
        'HTG' => {symbol: 'HTG', label: t('plugin.ecommerce.currencies.htg', default: 'Haitian Gourde')},
        'HUF' => {symbol: 'HUF', label: t('plugin.ecommerce.currencies.huf', default: 'Hungarian Forint')},
        'IDR' => {symbol: 'IDR', label: t('plugin.ecommerce.currencies.idr', default: 'Indonesian Rupiah')},
        'IEP' => {symbol: 'IEP', label: t('plugin.ecommerce.currencies.iep', default: 'Irish Pound')},
        'ILS' => {symbol: '₪', label: t('plugin.ecommerce.currencies.ils', default: 'Israeli New Sheqel')},
        'INR' => {symbol: '₹', label: t('plugin.ecommerce.currencies.inr', default: 'Indian Rupee')},
        'IQD' => {symbol: 'IQD', label: t('plugin.ecommerce.currencies.iqd', default: 'Iraqi Dinar')},
        'IRR' => {symbol: 'IRR', label: t('plugin.ecommerce.currencies.irr', default: 'Iranian Rial')},
        'ISK' => {symbol: 'ISK', label: t('plugin.ecommerce.currencies.isk', default: 'Icelandic Króna')},
        'ITL' => {symbol: 'ITL', label: t('plugin.ecommerce.currencies.itl', default: 'Italian Lira')},
        'JMD' => {symbol: 'JMD', label: t('plugin.ecommerce.currencies.jmd', default: 'Jamaican Dollar')},
        'JOD' => {symbol: 'JOD', label: t('plugin.ecommerce.currencies.jod', default: 'Jordanian Dinar')},
        'JPY' => {symbol: '¥', label: t('plugin.ecommerce.currencies.jpy', default: 'Japanese Yen')},
        'KES' => {symbol: 'KES', label: t('plugin.ecommerce.currencies.kes', default: 'Kenyan Shilling')},
        'KGS' => {symbol: 'KGS', label: t('plugin.ecommerce.currencies.kgs', default: 'Kyrgystani Som')},
        'KHR' => {symbol: 'KHR', label: t('plugin.ecommerce.currencies.khr', default: 'Cambodian Riel')},
        'KMF' => {symbol: 'KMF', label: t('plugin.ecommerce.currencies.kmf', default: 'Comorian Franc')},
        'KPW' => {symbol: 'KPW', label: t('plugin.ecommerce.currencies.kpw', default: 'North Korean Won')},
        'KRW' => {symbol: '₩', label: t('plugin.ecommerce.currencies.krw', default: 'South Korean Won')},
        'KWD' => {symbol: 'KWD', label: t('plugin.ecommerce.currencies.kwd', default: 'Kuwaiti Dinar')},
        'KYD' => {symbol: 'KYD', label: t('plugin.ecommerce.currencies.kyd', default: 'Cayman Islands Dollar')},
        'KZT' => {symbol: 'KZT', label: t('plugin.ecommerce.currencies.kzt', default: 'Kazakhstani Tenge')},
        'LAK' => {symbol: 'LAK', label: t('plugin.ecommerce.currencies.lak', default: 'Laotian Kip')},
        'LBP' => {symbol: 'LBP', label: t('plugin.ecommerce.currencies.lbp', default: 'Lebanese Pound')},
        'LKR' => {symbol: 'LKR', label: t('plugin.ecommerce.currencies.lkr', default: 'Sri Lankan Rupee')},
        'LRD' => {symbol: 'LRD', label: t('plugin.ecommerce.currencies.lrd', default: 'Liberian Dollar')},
        'LSL' => {symbol: 'LSL', label: t('plugin.ecommerce.currencies.lsl', default: 'Lesotho Loti')},
        'LTL' => {symbol: 'LTL', label: t('plugin.ecommerce.currencies.ltl', default: 'Lithuanian Litas')},
        'LVL' => {symbol: 'LVL', label: t('plugin.ecommerce.currencies.lvl', default: 'Latvian Lats')},
        'LYD' => {symbol: 'LYD', label: t('plugin.ecommerce.currencies.lyd', default: 'Libyan Dinar')},
        'MAD' => {symbol: 'MAD', label: t('plugin.ecommerce.currencies.mad', default: 'Moroccan Dirham')},
        'MDL' => {symbol: 'MDL', label: t('plugin.ecommerce.currencies.mdl', default: 'Moldovan Leu')},
        'MGA' => {symbol: 'MGA', label: t('plugin.ecommerce.currencies.mga', default: 'Malagasy Ariary')},
        'MKD' => {symbol: 'MKD', label: t('plugin.ecommerce.currencies.mkd', default: 'Macedonian Denar')},
        'MMK' => {symbol: 'MMK', label: t('plugin.ecommerce.currencies.mmk', default: 'Myanmar Kyat')},
        'MNT' => {symbol: 'MNT', label: t('plugin.ecommerce.currencies.mnt', default: 'Mongolian Tugrik')},
        'MOP' => {symbol: 'MOP', label: t('plugin.ecommerce.currencies.mop', default: 'Macanese Pataca')},
        'MRO' => {symbol: 'MRO', label: t('plugin.ecommerce.currencies.mro', default: 'Mauritanian Ouguiya')},
        'MUR' => {symbol: 'MUR', label: t('plugin.ecommerce.currencies.mur', default: 'Mauritian Rupee')},
        'MVR' => {symbol: 'MVR', label: t('plugin.ecommerce.currencies.mvr', default: 'Maldivian Rufiyaa')},
        'MWK' => {symbol: 'MWK', label: t('plugin.ecommerce.currencies.mwk', default: 'Malawian Kwacha')},
        'MXN' => {symbol: 'MX$', label: t('plugin.ecommerce.currencies.mxn', default: 'Mexican Peso')},
        'MYR' => {symbol: 'MYR', label: t('plugin.ecommerce.currencies.myr', default: 'Malaysian Ringgit')},
        'MZN' => {symbol: 'MZN', label: t('plugin.ecommerce.currencies.mzn', default: 'Mozambican Metical')},
        'NAD' => {symbol: 'NAD', label: t('plugin.ecommerce.currencies.nad', default: 'Namibian Dollar')},
        'NGN' => {symbol: 'NGN', label: t('plugin.ecommerce.currencies.ngn', default: 'Nigerian Naira')},
        'NIO' => {symbol: 'NIO', label: t('plugin.ecommerce.currencies.nio', default: 'Nicaraguan Córdoba')},
        'NOK' => {symbol: 'NOK', label: t('plugin.ecommerce.currencies.nok', default: 'Norwegian Krone')},
        'NPR' => {symbol: 'NPR', label: t('plugin.ecommerce.currencies.npr', default: 'Nepalese Rupee')},
        'NZD' => {symbol: 'NZ$', label: t('plugin.ecommerce.currencies.nzd', default: 'New Zealand Dollar')},
        'OMR' => {symbol: 'OMR', label: t('plugin.ecommerce.currencies.omr', default: 'Omani Rial')},
        'PAB' => {symbol: 'PAB', label: t('plugin.ecommerce.currencies.pab', default: 'Panamanian Balboa')},
        'PEN' => {symbol: 'PEN', label: t('plugin.ecommerce.currencies.pen', default: 'Peruvian Nuevo Sol')},
        'PGK' => {symbol: 'PGK', label: t('plugin.ecommerce.currencies.pgk', default: 'Papua New Guinean Kina')},
        'PHP' => {symbol: 'PHP', label: t('plugin.ecommerce.currencies.php', default: 'Philippine Peso')},
        'PKG' => {symbol: 'PKG', label: t('plugin.ecommerce.currencies.pkg', default: 'PKG')},
        'PKR' => {symbol: 'PKR', label: t('plugin.ecommerce.currencies.pkr', default: 'Pakistani Rupee')},
        'PLN' => {symbol: 'PLN', label: t('plugin.ecommerce.currencies.pln', default: 'Polish Zloty')},
        'PYG' => {symbol: 'PYG', label: t('plugin.ecommerce.currencies.pyg', default: 'Paraguayan Guarani')},
        'QAR' => {symbol: 'QAR', label: t('plugin.ecommerce.currencies.qar', default: 'Qatari Rial')},
        'RON' => {symbol: 'RON', label: t('plugin.ecommerce.currencies.ron', default: 'Romanian Leu')},
        'RSD' => {symbol: 'RSD', label: t('plugin.ecommerce.currencies.rsd', default: 'Serbian Dinar')},
        'RUB' => {symbol: 'RUB', label: t('plugin.ecommerce.currencies.rub', default: 'Russian Ruble')},
        'RWF' => {symbol: 'RWF', label: t('plugin.ecommerce.currencies.rwf', default: 'Rwandan Franc')},
        'SAR' => {symbol: 'SAR', label: t('plugin.ecommerce.currencies.sar', default: 'Saudi Riyal')},
        'SBD' => {symbol: 'SBD', label: t('plugin.ecommerce.currencies.sbd', default: 'Solomon Islands Dollar')},
        'SCR' => {symbol: 'SCR', label: t('plugin.ecommerce.currencies.scr', default: 'Seychellois Rupee')},
        'SDG' => {symbol: 'SDG', label: t('plugin.ecommerce.currencies.sdg', default: 'Sudanese Pound')},
        'SEK' => {symbol: 'SEK', label: t('plugin.ecommerce.currencies.sek', default: 'Swedish Krona')},
        'SGD' => {symbol: 'SGD', label: t('plugin.ecommerce.currencies.sgd', default: 'Singapore Dollar')},
        'SHP' => {symbol: 'SHP', label: t('plugin.ecommerce.currencies.shp', default: 'St. Helena Pound')},
        'SKK' => {symbol: 'SKK', label: t('plugin.ecommerce.currencies.skk', default: 'Slovak Koruna')},
        'SLL' => {symbol: 'SLL', label: t('plugin.ecommerce.currencies.sll', default: 'Sierra Leonean Leone')},
        'SOS' => {symbol: 'SOS', label: t('plugin.ecommerce.currencies.sos', default: 'Somali Shilling')},
        'SRD' => {symbol: 'SRD', label: t('plugin.ecommerce.currencies.srd', default: 'Surinamese Dollar')},
        'STD' => {symbol: 'STD', label: t('plugin.ecommerce.currencies.std', default: 'São Tomé & Príncipe Dobra')},
        'SVC' => {symbol: 'SVC', label: t('plugin.ecommerce.currencies.svc', default: 'Salvadoran Colón')},
        'SYP' => {symbol: 'SYP', label: t('plugin.ecommerce.currencies.syp', default: 'Syrian Pound')},
        'SZL' => {symbol: 'SZL', label: t('plugin.ecommerce.currencies.szl', default: 'Swazi Lilangeni')},
        'THB' => {symbol: 'THB', label: t('plugin.ecommerce.currencies.thb', default: 'Thai Baht')},
        'TJS' => {symbol: 'TJS', label: t('plugin.ecommerce.currencies.tjs', default: 'Tajikistani Somoni')},
        'TMT' => {symbol: 'TMT', label: t('plugin.ecommerce.currencies.tmt', default: 'Turkmenistani Manat')},
        'TND' => {symbol: 'TND', label: t('plugin.ecommerce.currencies.tnd', default: 'Tunisian Dinar')},
        'TOP' => {symbol: 'TOP', label: t('plugin.ecommerce.currencies.top', default: 'Tongan Paʻanga')},
        'TRY' => {symbol: 'TRY', label: t('plugin.ecommerce.currencies.try', default: 'Turkish Lira')},
        'TTD' => {symbol: 'TTD', label: t('plugin.ecommerce.currencies.ttd', default: 'Trinidad & Tobago Dollar')},
        'TWD' => {symbol: 'NT$', label: t('plugin.ecommerce.currencies.twd', default: 'New Taiwan Dollar')},
        'TZS' => {symbol: 'TZS', label: t('plugin.ecommerce.currencies.tzs', default: 'Tanzanian Shilling')},
        'UAH' => {symbol: 'UAH', label: t('plugin.ecommerce.currencies.uah', default: 'Ukrainian Hryvnia')},
        'UGX' => {symbol: 'UGX', label: t('plugin.ecommerce.currencies.ugx', default: 'Ugandan Shilling')},
        'USD' => {symbol: '$', label: t('plugin.ecommerce.currencies.usd', default: 'US Dollar')},
        'UYU' => {symbol: 'UYU', label: t('plugin.ecommerce.currencies.uyu', default: 'Uruguayan Peso')},
        'UZS' => {symbol: 'UZS', label: t('plugin.ecommerce.currencies.uzs', default: 'Uzbekistani Som')},
        'VEF' => {symbol: 'VEF', label: t('plugin.ecommerce.currencies.vef', default: 'Venezuelan Bolívar')},
        'VND' => {symbol: '₫', label: t('plugin.ecommerce.currencies.vnd', default: 'Vietnamese Dong')},
        'VUV' => {symbol: 'VUV', label: t('plugin.ecommerce.currencies.vuv', default: 'Vanuatu Vatu')},
        'WST' => {symbol: 'WST', label: t('plugin.ecommerce.currencies.wst', default: 'Samoan Tala')},
        'XAF' => {symbol: 'FCFA', label: t('plugin.ecommerce.currencies.xaf', default: 'Central African CFA Franc')},
        'XCD' => {symbol: 'EC$', label: t('plugin.ecommerce.currencies.xcd', default: 'East Caribbean Dollar')},
        'XDR' => {symbol: 'XDR', label: t('plugin.ecommerce.currencies.xdr', default: 'Special Drawing Rights')},
        'XOF' => {symbol: 'CFA', label: t('plugin.ecommerce.currencies.xof', default: 'West African CFA Franc')},
        'XPF' => {symbol: 'CFPF', label: t('plugin.ecommerce.currencies.xpf', default: 'CFP Franc')},
        'YER' => {symbol: 'YER', label: t('plugin.ecommerce.currencies.yer', default: 'Yemeni Rial')},
        'ZAR' => {symbol: 'ZAR', label: t('plugin.ecommerce.currencies.zar', default: 'South African Rand')},
        'ZMK' => {symbol: '1968–2012 ', label: t('plugin.ecommerce.currencies.zmk', default: 'Zambian Kwacha')},
        'ZMW' => {symbol: 'ZMW', label: t('plugin.ecommerce.currencies.zmw', default: 'Zambian Kwacha')},
        'ZWL' => {symbol: '2009 ', label: t('plugin.ecommerce.currencies.zwl', default: 'Zimbabwean Dollar')}
      }
      hooks_run('ecommerce_currencies', currencies)
      currencies
    }.call
  end

  # use in add cart
  def e_add_data_product(data, product_id)
    post = CamaleonCms::Post.find(product_id).decorate
    attributes = post.attributes
    attributes[:content] = ''
    data[:product_title] = post.the_title
    data[:price] = post.get_field_value(:ecommerce_price)
    data[:weight] = post.get_field_value(:ecommerce_weight)
    data[:tax_rate_id] = post.get_field_value(:ecommerce_tax)
    tax_product = current_site.tax_rates.find(data[:tax_rate_id]).options[:rate].to_f  rescue 0
    data[:tax_percent] = tax_product
    data[:tax] = data[:price].to_f * data[:tax_percent] / 100 rescue 0
    data[:currency_code] = current_site.currency_code
    metas = {}
    post.metas.map{|m| metas[m.key] = m.value }
    data.merge(post: attributes, fields: post.get_field_values_hash, meta: metas)
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
