require 'nokogiri'

class GooglePlay
  module Parser
    def parse_app(html)
      doc = Nokogiri.HTML(html)
      GooglePlay::App.new(
        :name           => parse_app_name(doc),
        :image_url      => parse_app_image_url(doc),
        :developer      => parse_app_developer(doc),
        :developer_mail => parse_app_developer_mail(doc),
        :developer_web  => parse_app_developer_web(doc),
        :category       => parse_app_category(doc),
        :rating_count   => parse_app_rating_count(doc),
        :rating_counts  => parse_app_rating_counts(doc),
        :rating_average => parse_app_rating_average(doc),
        :description    => parse_app_description(doc),
        :recent_change  => parse_app_recent_change(doc),
        :last_update    => parse_app_last_update(doc),
        :file_size      => parse_app_file_size(doc),
        :downloads      => parse_app_downloads(doc),
        :version        => parse_app_version(doc),
        :os_requried    => parse_app_os_required(doc)
      )
    end

    def parse_review(html)
      doc = Nokogiri.HTML(html)
      doc.css('.single-review').map do |node|
        GooglePlay::Review.new(
          :id      => parse_review_id(node),
          :user    => parse_review_user(node),
          :user_id => parse_review_user_id(node),
          :date    => parse_review_date(node),
          :rating  => parse_review_rating(node),
          :title   => parse_review_title(node),
          :text    => parse_review_text(node)
        )
      end
    end

    private
    def parse_review_id(node)
      a = node.xpath(".//a[@class='reviews-permalink']").first
      a['href'].match(/reviewId=(\w+)/)[1]
    end

    def parse_review_user(node)
      # a = node.xpath(".//span[@class='author-name']/a").first
      # a.nil? ? '' : a.text
      if node.at_css('.author-name')
        node.at_css('.author-name').text.strip
      else
        'Unknown'
      end
    end

    def parse_review_user_id(node)
      a = node.xpath(".//span[@class='author-name']/a").first
      a.nil? ? nil : a['href'].match(/id=(\w+)/)[1].to_i
    end

    def parse_review_date(node)
      text = node.xpath(".//span[@class='review-date']").text
      begin
        Date.parse(text)
      rescue
        text =~ /(\d+)\D+(\d+)\D+(\d+)/
        Date.new($1.to_i, $2.to_i, $3.to_i)
      end
    end

    def parse_review_rating(node)
      div = node.xpath(".//div[@class='current-rating']").first
      width = div['style'].match(/width: (\d+)%/)[1].to_i
      width / 20
    end

    def parse_review_title(node)
      # node.xpath(".//span[@class='review-title']").text
      if node.at_css('.review-title')
        node.at_css('.review-title').text.strip
      else
        ''
      end
    end

    def parse_review_text(node)
      # dup = node.dup
      # dup.xpath(".//div[@class='review-link']").remove
      # dup.xpath(".//span[@class='review-title']").remove
      # dup.xpath(".//div[@class='review-body']").text.strip

      if node.at_css('.review-body')
        node.at_css('.review-body').text.strip
      else
        ''
      end
    end

    def parse_app_name(node)
      node.xpath("//div[@class='document-title']/div").text
    end

    def parse_app_image_url(node)
      node.xpath("//img[@class='cover-image']").first['src']
    end

    def parse_app_developer(node)
      node.xpath("//a[@class='document-subtitle primary']/span[@itemprop='name']").text
    end

    def parse_app_developer_web(node)
      a = node.xpath("//a[@class='dev-link']")
      (a.size == 2) ? a.first['href'] : nil
    end

    def parse_app_developer_mail(node)
      a = node.xpath("//a[@class='dev-link']")
      if a.size == 0
        nil
      else
        a[a.size - 1]['href'].sub('mailto:', '')
      end
    end

    def parse_app_category(node)
      a = node.xpath("//a[@class='document-subtitle category']").first
      a['href'].match(/category\/(.+)$/)[1].downcase
    end

    def parse_app_rating_count(node)
      node.xpath("//div[@class='stars-count']").text.match(/(\d+)/)[1]
    end

    def parse_app_rating_counts(node)
      node.xpath("//span[@class='bar-number']").map { |n| n.text.to_i }
    end

    def parse_app_rating_average(node)
      node.xpath("//div[@class='score']").text.to_f
    end

    def parse_app_description(node)
      node.xpath("//div[@class='id-app-orig-desc']").inner_html
    end

    def parse_app_recent_change(node)
      node.xpath("//div[@class='recent-change']")
      .map { |n| n.text }
      .join("\n")
    end

    def parse_app_last_update(node)
      text = node.xpath("//div[@itemprop='datePublished']").text
      begin
        Date.parse(text)
      rescue
        text =~ /(\d+)\D+(\d+)\D+(\d+)/
        Date.new($1.to_i, $2.to_i, $3.to_i)
      end
    end

    def parse_app_file_size(node)
      file_size = node.xpath("//div[@itemprop='fileSize']").text.strip
      (file_size =~ /\d+/) ? file_size : :device_dependent
    end

    def parse_app_downloads(node)
      node.xpath("//div[@itemprop='numDownloads']").text.strip
    end

    def parse_app_version(node)
      version = node.xpath("//div[@itemprop='softwareVersion']").text.strip
      (version =~ /\d+/) ? version : :device_dependent
    end

    def parse_app_os_required(node)
      text = node.xpath("//div[@itemprop='operatingSystems']").text
      if text =~ /([\d\.]+)/
        $1
      else
        :device_dependent
      end
    end
  end
end
