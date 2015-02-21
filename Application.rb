require 'mechanize'
require 'timeout'
require 'json'
require './lib/httpagent'
require './lib/widget_finder'

@agent = Mechanize.new


def time_diff_milli(start, finish)
  (finish - start) * 1000.0
end

def timeOutPart (timeout, url, site)

  Timeout::timeout(timeout) {
    address = 'http://' + url.gsub("\n",'')
    t1 = Time.now
    page = @agent.get(address)
    source = page.body
    t2 = Time.now
    responseTime = time_diff_milli t1, t2

    begin

    t1 = Time.now
    page.links.each do |link|
      break if t1 + 0.5 < Time.now
      puts 'ASDASD'
      next if link.uri.to_s[0] == "?" || link.uri.to_s.include?('mailto')
      subPage = @agent.click(link)
      unless page.uri.host.equal? subPage.uri.host
      @agent.back
      next
      end
      subSource = subPage.body
      source = source + subSource
      @agent.back
    end
    puts ' LOPPU'
    rescue Mechanize::UnsupportedSchemeError
    rescue Net::HTTP::Persistent::Error
    rescue URI::InvalidComponentError
    rescue

    end
    begin
      page = @agent.head address
      server_version = page.header['server']
      if page.header.key? 'x-powered-by'
        framework_version = page.header['x-powered-by']
      end
    rescue Exception
    end

    wf = WidgetFinder.new(source)
    arr = wf.has_widgets

    site["Address"] = address
    site["ResponseTime"] = responseTime
    site["Server Version"] = server_version
    site["Framework"] = framework_version
    site["Widgets"] = arr
  }
end

def scrapeSites (fileName)
  File.open( fileName ).each do |line|
    site = Hash.new
    begin
      timeOutPart(7, line, site)
      p site
      hasKey = site.has_key?("Framework")
      unless site[Widgets].nil? && !hasKey
        File.open("data/"+line + ".json","w") do |f|
          f.write(site.to_json)
        end
      end

    rescue SocketError => se
      puts 'SocketError'
    rescue  Mechanize::ResponseCodeError
      puts 'ResponseCodeError'
    rescue Timeout::Error => se
      puts 'TimeoutError'
    rescue
    end

  end
end

scrapeSites('data/net.txt')