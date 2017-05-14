require 'open-uri'
require 'nokogiri'
require_relative './people'

class ScrapeMp
  def parser
    #DataMapper.auto_upgrade!
    url_all = "http://www.lutskrada.gov.ua/deputy?field_person_district_tid=All&field_person_faction_tid=All"
    page_number = get_page(url_all)
    pages = page_number.css('.pager-last a')[0][:href][/page=.+/][/\d+/].to_i
    i = 2000
    (0..pages).each do |p|
      url = "http://www.lutskrada.gov.ua/deputy?field_person_district_tid=All&field_person_faction_tid=All&page=#{p}"
      page = get_page(url)
      page.css('table.views-view-grid tr').each do |tr|
        tr.css('td').each do |mp|
         full_name = mp.css('.views-field-title a').text
         faction = mp.css('.views-field-field-person-faction a').text
         photo_url = mp.css('.views-field-field-person-photo img')[0][:src]
         i = i + 1
         scrape_mp(full_name, nil, faction, photo_url, i)
        end
      end
    end
    #resigned_mp()
    create_mer()
  end
  def create_mer
    #TODO create mer Sadovoy
    names = %w{Поліщук Ігор Ігорович}
    People.first_or_create(
        first_name: names[1],
        middle_name: names[2],
        last_name: names[0],
        full_name: names.join(' '),
        deputy_id: 1111,
        okrug: nil,
        photo_url: "http://www.lutskrada.gov.ua/sites/default/files/polishchuk_igor_igorovych_1.jpg",
        faction: nil,
        end_date: nil,
        created_at: "9999-12-31"
    )
  end
  def get_page(url)
    Nokogiri::HTML(open(url, "User-Agent" => "HTTP_USER_AGENT:Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.47"), nil, 'utf-8')
  end
  def resigned_mp
    uri = ""
    page_resigned = get_page(uri)
    scrape_mp( )
  end
  def scrape_mp(fio, okrug, party, image, rada_id, date_end=nil)
    party = case
              when party[/Солідарність/]
                "Блок Петра Порошенка"
              when party[/Самопоміч/]
                "Самопоміч"
              when party[/Батьківщина/]
                "Батьківщина"
              when party[/Свобода/]
                "Свобода"
              when party[/УКРОП/]
                "УКРОП"
              when party[/Народний контроль/]
                "Народний контроль"
              when party[/Радикальної Партії/]
                "Радикальна партія"
              when (fio == "Козлюк Олександр Євгенович" or fio == "Ткачук Євгеній Євгенович" or fio == "Яручик Микола Олександрович")
                "Блок Петра Порошенка"
              else
                party
            end
    name = fio.gsub(/\s{2,}/,' ')
    name_array = name.split(' ')
    people = People.first(
        first_name: name_array[1],
        middle_name: name_array[2],
        last_name: name_array[0],
        full_name: name_array.join(' '),
        okrug: okrug,
        photo_url: image,
        faction: party,
    )
    unless people.nil?
    people.update(end_date:  date_end,  updated_at: Time.now)
    else
      People.create(
          first_name: name_array[1],
          middle_name: name_array[2],
          last_name: name_array[0],
          full_name: name_array.join(' '),
          deputy_id: rada_id,
          okrug: okrug,
          photo_url: image,
          faction: party,
          end_date:  date_end,
          created_at: Time.now,
          updated_at: Time.now
      )
    end
  end
end
unless ENV['RACK_ENV']
  ScrapeMp.new
end


