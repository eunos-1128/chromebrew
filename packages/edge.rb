require 'package'

class Edge < Package
  description 'Microsoft Edge is the fast and secure browser'
  homepage 'https://www.microsoft.com/en-us/edge'
  version '130.0.2849.80-1'
  license 'MIT'
  compatibility 'x86_64'
  min_glibc '2.29'
  source_url "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_#{version}_amd64.deb"
  source_sha256 '1b6f5743703e6da81c65c28dbcfd949d605466e226acc7cde9efbd4beabfa05d'

  depends_on 'at_spi2_core'
  depends_on 'libcom_err'
  depends_on 'libxcomposite'
  depends_on 'libxdamage'
  depends_on 'sommelier'

  no_compile_needed
  no_shrink

  def self.patch
    # Make sure the executable path is correct.
    system "sed -i 's,/usr/bin,#{CREW_PREFIX}/bin,' ./usr/share/applications/microsoft-edge.desktop"
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    FileUtils.mv './usr/share', CREW_DEST_PREFIX
    FileUtils.mv './opt/microsoft/msedge', "#{CREW_DEST_PREFIX}/share"
    FileUtils.ln_sf "#{CREW_PREFIX}/share/msedge/msedge", "#{CREW_DEST_PREFIX}/bin/edge"
    FileUtils.ln_sf "#{CREW_PREFIX}/share/msedge/msedge", "#{CREW_DEST_PREFIX}/bin/msedge"
    FileUtils.ln_sf "#{CREW_PREFIX}/share/msedge/msedge", "#{CREW_DEST_PREFIX}/bin/microsoft-edge"
    FileUtils.ln_sf "#{CREW_PREFIX}/share/msedge/msedge", "#{CREW_DEST_PREFIX}/bin/microsoft-edge-stable"
    FileUtils.ln_sf "#{CREW_MAN_PREFIX}/man1/microsoft-edge.1.gz", "#{CREW_DEST_MAN_PREFIX}/man1/edge.1.gz"
    FileUtils.ln_sf "#{CREW_MAN_PREFIX}/man1/microsoft-edge.1.gz", "#{CREW_DEST_MAN_PREFIX}/man1/msedge.1.gz"

    # Add icon for use with crew-launcher
    downloader 'https://cdn.icon-icons.com/icons2/2552/PNG/128/edge_browser_logo_icon_152998.png',
               '524373bb044a48b8e72f7ffed1e0a95ed88f89e1fe29a065e52a32486bcb9f99', 'microsoft-edge.png'

    icon_path = "#{CREW_DEST_PREFIX}/share/icons/hicolor/128x128/apps"
    FileUtils.mkdir_p icon_path.to_s
    FileUtils.mv 'microsoft-edge.png', icon_path.to_s
  end

  def self.postinstall
    ExitMessage.add "\nType 'edge' to get started.\n"
  end
end
