require 'rubygems'
require 'open-uri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

ORDER_NUMBER_LOWER_LIMIT = 85180
ORDER_NUMBER_UPPER_LIMIT = 85190
ZIPCODE = 75063
queue = 0

class OrderStatus
  attr_accessor :response
  
  def initialize(response)
    self.response = response
  end
  
  def nil?
    err = self.response.scan("We're sorry, but the information you entered was not").to_s
    err.empty? == true ? false : true
  end
  
  def canceled?
    cancel = self.response.scan("Canceled")[0].to_s
    cancel.empty? == true ? false : true
  end
  
  def name
    name = self.response.scan(/Customer:\s*\w*/).to_s
    name.gsub!(/Customer:\s*/, "")
  end
  
  def order
    order = self.response.scan(/Order Number:\s*\w*/).to_s
    order.gsub!(/Order Number:\s*/, "")
  end
  
  def date
    date = self.response.scan(/Date Ordered:.*/).to_s
    date.gsub!(/Date Ordered:\s*/, "")
    date.gsub!(/\s/, "")
  end
  
  def ship_date
    ship_date = self.response.scan(/\<td width="6%".*/)[5]
    ship_date.remove_p_tag
  end
  
  def shipped
    shipped = self.response.scan(/\<td width="5%".*/)[3].scan(/[01]/).to_s.to_i
  end
  
  def ship_info
    ship_info = self.response.scan(/\<td width="6%".*/)[7]
    ship_info.remove_p_tag
  end
  
  def display(q)
    "#{name.slice(0..20).ljust(20)} | #{order} | #{date} | #{shipped} | #{q.rjust(2)} | #{ship_date} #{ship_info}"    
  end
end

class String
  # add this to the String class to help clean up some cruft
  def remove_p_tag
    self.gsub!(/^.*\<p\>/, "")
    self.gsub!(/\<\/p\>.*$/, "")
  end
end

puts "Name                 | Order | Order Dt |Yn | Qu | Ship Info     "
for order_number in ORDER_NUMBER_LOWER_LIMIT..ORDER_NUMBER_UPPER_LIMIT
  @url = "https://www.wireless.att.com/order_status/order_status_results.jsp?fromwhere=order_status&vMethod=ordernum&vNumber=#{order_number}&ZipCode=#{ZIPCODE}&x=48&y=6Passphrase=Q9RJ53"

  # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
  open( @url,
        "User-Agent" => "Ruby/#{RUBY_VERSION}",
        "From" => "email@addr.com",
        "Referer" => "https://www.wireless.att.com/order_status") do |f|
      # Save the response body
      stat = OrderStatus.new(f.read)
      if stat.canceled?
        puts "#{order_number} canceled"
      elsif !stat.nil?
        # calculate the queue
        queue += 1 if stat.shipped == 0
        display_queue = stat.shipped == 0 ? queue.to_s : ""
      
        # display the info
        puts stat.display(display_queue)
      else
        puts "#{order_number} not found"
      end
  end
end
