module StaticAssets

=begin

  file_attributes = StaticAssets.data_url_attributes(data_url)

returns

  {
    mime_type: 'image/png',
    content: image_bin_content,
  }

=end

  def self.data_url_attributes(data_url)
    data = {}
    if data_url =~ /^data:(.+?);base64,(.+?)$/
      data[:mime_type] = $1
      data[:content]   = Base64.decode64($2)
      return data
    end
    fail "Unable to parse data url: #{data_url.substr(0, 100)}"
  end

=begin

store image 1:1 in backend and return filename

  filename = StaticAssets.store_raw( content, content_type )

returns

  filename # hash.png

=end

  def self.store_raw(content, content_type)
    Store.remove(object: 'System::Logo', o_id: 1)
    file = Store.add(
      object: 'System::Logo',
      o_id: 1,
      data: content,
      filename: 'logo_raw',
      preferences: {
        'Content-Type' => content_type
      },
    )
    filename(file)
  end

=begin

read image 1:1 size in backend and return file (Store model)

  store = StaticAssets.read_raw

returns

  store # Store model, e.g. store.content or store.preferences

=end

  def self.read_raw
    list = Store.list(object: 'System::Logo', o_id: 1)
    if list && list[0]
      return Store.find( list[0] )
    end
    fail 'No such raw logo!'
  end

=begin

store image in right size (resized) in backend and return filename

  filename = StaticAssets.store( content, content_type )

returns

  filename # hash.png

=end

  def self.store(content, content_type)
    Store.remove(object: 'System::Logo', o_id: 2)
    file = Store.add(
      object: 'System::Logo',
      o_id: 2,
      data: content,
      filename: 'logo',
      preferences: {
        'Content-Type' => content_type
      },
    )
    StaticAssets.sync
    filename(file)
  end

=begin

read image size from backend (if not exists, read 1:1 size) and return file (Store model)

  store = StaticAssets.read

returns

  store # Store model, e.g. store.content or store.preferences

=end

  def self.read

    # use reduced dimensions
    list = Store.list(object: 'System::Logo', o_id: 2)

    # as fallback use 1:1
    if !list || !list[0]
      list = Store.list(object: 'System::Logo', o_id: 1)
    end

    # store hash in config
    if list && list[0]
      file = Store.find(list[0])
      filelocation = filename(file)
      Setting.set('product_logo', filelocation)
      return file
    end
  end

=begin

generate filename based on Store model

  filename = StaticAssets.filename(store)

=end

  def self.filename(file)
    hash = Digest::MD5.hexdigest(file.content)
    extention = ''
    if file.preferences['Content-Type'] =~ /jpg|jpeg/i
      extention = '.jpg'
    elsif file.preferences['Content-Type'] =~ /png/i
      extention = '.png'
    end
    "#{hash}#{extention}"
  end

=begin

sync image to fs (public/assets/images/hash.png)

  StaticAssets.sync

=end

  def self.sync
    file = read
    return if !file
    path = "#{Rails.root}/public/assets/images/#{filename(file)}"
    File.open( path, 'wb' ) do |f|
      f.puts file.content
    end
  end
end
