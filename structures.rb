class ScreenshotsGroup
  attr_reader :name, :screenshots, :dirpath

  def initialize(name:, dirpath:)
    @name = name
    @screenshots = []
    @dirpath = dirpath
  end

  def screenshot_names
    @screenshot_names ||= screenshots.map(&:name).uniq
  end

  def get_screenshot(viewport:, name:, role:)
    screenshots.find { _1.viewport == viewport && _1.name == name && _1.role == role }
  end

  def self.build_from_yaml(dirpath:)
    yaml_tree = YAML.load_file(File.join(__dir__, "screenshots.yaml"))

    yaml_tree.map do |group_name, screenshots_names|
      group = new(name: group_name, dirpath:)
      screenshots_names.each do |name|
        %i[desktop mobile].each do |viewport|
          %i[avant après].each do |role|
            group.screenshots << Screenshot.new(viewport: viewport, name: name, group: group, role: role)
          end
        end
      end
      group
    end
  end
end

class Screenshot
  attr_reader :viewport, :name, :group, :role

  def initialize(viewport:, name:, group:, role:)
    @viewport = viewport
    @name = name
    @group = group
    @role = role.to_sym

    raise "invalid viewport '#{viewport}'" unless %i[desktop mobile].include?(@viewport)
    raise "invalid role '#{role}'" unless %i[avant après].include?(@role)
  end

  def filename
    @filename ||= "screenshot-#{viewport}-#{group.name}-#{name}.png"
  end

  def relpath
    @relpath ||= File.join(role.to_s, filename)
  end

  def path
    @path ||= File.join(group.dirpath, relpath)
  end

  def width
    dimensions[0]
  end

  def height
    dimensions[1]
  end

  def dimensions
    @dimensions ||= IO.read(path)[0x10..0x18].unpack("NN")
  end
end
