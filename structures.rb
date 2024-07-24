class ScreenshotsGroup
  attr_reader :name, :screenshots

  def initialize(name)
    @name = name
    @screenshots = []
  end

  def screenshot_names
    @screenshot_names ||= screenshots.map(&:name).uniq
  end

  def get_screenshot(viewport:, name:)
    screenshots.find { _1.viewport == viewport && _1.name == name }
  end
end

class Screenshot
  attr_reader :viewport, :name, :group

  def initialize(viewport:, name:, group:)
    @viewport = viewport
    @name = name
    @group = group
  end

  def filename
    @filename ||= "screenshot-#{viewport}-#{group.name}-#{name}.png"
  end
end
