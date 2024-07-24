require "fileutils"
require_relative "structures"

# rubocop:disable Metrics/BlockLength

RSpec.describe "public pages", type: :feature, js: true do
  before(:each) do
    Capybara.register_driver :mobile do |capybara_app|
      Capybara::Selenium::Driver.new(
        capybara_app,
        browser: :firefox,
        options: Selenium::WebDriver::Firefox::Options.new(args: %w[--headless --width=390 --height=844])
      )
    end
    Capybara.register_driver :desktop do |capybara_app|
      Capybara::Selenium::Driver.new(
        capybara_app,
        browser: :firefox,
        options: Selenium::WebDriver::Firefox::Options.new(args: %w[--headless --width=1280 --height=1024])
      )
    end
  end

  context "default" do
    let(:now) { Time.zone.now }
    # from spec/features/users/online_booking/default_spec.rb
    let!(:territory92) { create(:territory, departement_number: "92") }
    let!(:organisation) { create(:organisation, :with_contact, territory: territory92) }
    let!(:service_medical) { create(:service, name: "Service Médical") }
    let!(:service_social) { create(:service, name: "Service Social") }
    let!(:motif_vaccination) { create(:motif, name: "Vaccination", organisation: organisation, restriction_for_rdv: nil, service: service_medical) }
    let!(:motif_tel) { create(:motif, :by_phone, name: "Télé consultation", organisation: organisation, restriction_for_rdv: nil, service: service_medical) }
    let!(:motif_collectif) { create(:motif, :collectif, name: "Atelier collectif", organisation: organisation, restriction_for_rdv: nil, service: service_social) }
    let!(:motif_rsa) { create(:motif, name: "poursuite RSA", organisation: organisation, restriction_for_rdv: nil, service: service_social) }
    let!(:lieu_centre) { create(:lieu, name: "MDS Centre", organisation: organisation) }
    let!(:lieu_est) { create(:lieu, name: "MJD Est", organisation: organisation) }
    let!(:plage_ouverture_vaccination) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_vaccination], lieu: lieu_centre, organisation: organisation) }
    let!(:plage_ouverture_motif_tel) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_tel], lieu: lieu_centre, organisation: organisation) }
    let!(:plage_ouverture_rsa) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_rsa], lieu: lieu_est, organisation: organisation) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let!(:rdv_collectifs) do
      3.times do |i|
        create(
          :rdv,
          starts_at: now + 1.month + i.days + 10.hours,
          motif: motif_collectif,
          lieu: lieu_est,
          organisation: organisation,
          agents: [agent]
        )
      end
    end

    let!(:user) { create(:user, first_name: "Jean", last_name: "Dupont", email: "jean.dupont@lycos.fr", password: "Rdvservicepublictest1!") }

    it "screenshots" do
      @viewports = { mobile: {}, desktop: {} }
      @viewports.each_key do |viewport|
        puts "--- running for #{viewport} ---"
        @current_viewport = viewport
        run_screenshots
      end

      page.driver.browser.close
    end

    def enter_group(name)
      @current_group_name = name
      puts "  group #{@current_group_name}"
    end

    def run_screenshots # rubocop:disable Metrics/MethodLength
      Capybara.current_driver = @current_viewport

      %w[mairie aide-numerique].each do |domain|
        base_url = "http://www.rdv-#{domain}.localhost:3000"
        enter_group domain
        visit base_url
        take_screenshot "homepage"
        visit "#{base_url}/presentation_agent"
        take_screenshot "presentation-agent"
        visit "#{base_url}/prendre_rdv"
        take_screenshot "prendre-rdv"
      end

      enter_group "static-pages"
      %w[/contact /mds /accessibility /mentions_legales /cgu /politique_de_confidentialite /domaines /stats/ /stats/notifications /connexion_super_admins].each do |path|
        visit path
        take_screenshot path.parameterize
      end

      enter_group "prise-rdv"
      visit root_path
      take_screenshot "home"
      # from spec/features/users/online_booking/default_spec.rb
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
      find("#search_departement", visible: :all) # permet d'attendre que l'élément soit dans le DOM
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")
      click_button("Rechercher")
      take_screenshot "selection-service"
      click_on "Service Médical"
      take_screenshot "selection-motif"
      click_on "Vaccination"
      take_screenshot "selection-lieu"
      find(".card-title", text: /MDS Centre/).ancestor(".card").find("a.stretched-link").click
      take_screenshot "selection-creneau"
      click_on "sem. prochaine"
      first(:link, "11:00").click
      take_screenshot "connexion"
      fill_in "user_email", with: "jean.dupont@lycos.fr"
      fill_in "user[password]", with: "Rdvservicepublictest1!"
      click_button "Se connecter"
      take_screenshot "etape-informations-usager"
      click_on "Continuer"
      take_screenshot "etape-choix-usager"
      click_on "Continuer"
      take_screenshot "etape-confirmation"
      click_on "Confirmer mon RDV"

      enter_group "user-account"
      visit "/users/informations"
      take_screenshot "mes-informations"
      click_on "Ajouter un proche"
      take_screenshot "modale-ajouter-un-proche"
      first_name = { mobile: "Bryony", desktop: "Karim" }[@current_viewport]
      within "#modal-holder" do
        fill_in "user_first_name", with: first_name
        fill_in "user_last_name", with: "Dupont"
        click_on "Enregistrer"
      end
      take_screenshot "DEBUG"
      find("div.col", text: /#{first_name}/).ancestor("li").click_on "Modifier"
      take_screenshot "modifier-un-proche"
      visit "/users/edit"
      take_screenshot "mon-compte"
      visit "/users/rdvs"
      take_screenshot "mes-rdvs"
      first(".btn", text: "Déplacer le RDV").click
      take_screenshot "deplacer-rdv"
      first(:link, "08:00").click
      take_screenshot "deplacer-rdv-confirmation"
      click_on "Confirmer le nouveau créneau"
      click_on "Annuler le RDV"
      take_screenshot "annuler-rdv"

      enter_group "invitation"
      visit "/invitation"
      take_screenshot "invitation-manuelle"
      visit "/users/user_name_initials_verification/new"
      take_screenshot "verification-initiales"
      # user = User.create!(first_name: "Claudia", last_name: "La Pobla", organisations: [organisation])
      # user.invite!(domain: Domain::RDV_SOLIDARITES, invited_by: agent)
      # fill_in "invitation_token", with: user.invitation_token
      # click_on "Créer son compte"
      # user.assign_rdv_invitation_token
      # user.save!
      # visit "/prendre_rdv?address=Garennecolombes&city_code=92035&departement=92&latitude=48.904582&longitude=2.25391&service_id=1&street_ban_id=92035_7145&invitation_token=#{user.rdv_invitation_token}"
      # exit

      enter_group "prise-rdv-collectif"
      visit root_path
      # from spec/features/users/online_booking/default_spec.rb
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
      find("#search_departement", visible: :all)
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")
      click_button("Rechercher")
      click_on "Service Social"
      take_screenshot "selection-motif"
      click_on "Atelier collectif"
      find(".card-title", text: /MJD Est/).ancestor(".card").find("a.stretched-link").click
      take_screenshot "selection-creneau"
      first(:link, "S'inscrire").click
      click_on "Continuer"
      click_on "Continuer"
      take_screenshot "etape-confirmation"
      click_on "Confirmer ma participation"
      take_screenshot "rdv"
      click_on "modifier"
      take_screenshot "modifier-participants"
      find('button[aria-controls="modal-header-menu"]').click if @current_viewport == :mobile
      take_screenshot "menu-user-logged-in"
      click_on "Déconnexion"

      enter_group "inscription"
      visit "/users/sign_up"
      take_screenshot "inscription"
      fill_in "user_first_name", with: "Zineb"
      fill_in "user_last_name", with: "Moussaoui"
      fill_in "user_email", with: "zmous@wanadoo.fr"
      click_on "Je m'inscris"
      visit "/users/confirmation?confirmation_token=#{User.find_by(email: 'zmous@wanadoo.fr').confirmation_token}"
      take_screenshot "definir-mot-de-passe"
      visit "/users/password/new"
      take_screenshot "mot-de-passe-oublie"
    end

    def take_screenshot(name)
      sleep 0.2
      @groups ||= {}
      @groups[@current_group_name] ||= ScreenshotsGroup.new(@current_group_name)
      group = @groups[@current_group_name]
      screenshot = Screenshot.new(viewport: @current_viewport, name:, group:)
      path = File.join ENV["OUTPUT_DIR"], screenshot.filename
      page.driver.browser.save_full_page_screenshot path
    end
  end
end

# rubocop:enable Metrics/BlockLength
