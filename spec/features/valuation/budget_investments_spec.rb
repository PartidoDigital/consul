require 'rails_helper'

feature 'Valuation budget investments' do

  let(:budget) { create(:budget, :valuating) }
  let(:valuator) do
    create(:valuator, user: create(:user, username: 'Rachel', email: 'rachel@valuators.org'))
  end

  background do
    login_as(valuator.user)
  end

  scenario 'Disabled with a feature flag' do
    Setting['feature.budgets'] = nil
    expect{
      visit valuation_budget_budget_investments_path(create(:budget))
    }.to raise_exception(FeatureFlags::FeatureDisabled)

    Setting['feature.budgets'] = true
  end

  scenario 'Display link to valuation section' do
    visit root_path
    expect(page).to have_link "Valuation", href: valuation_root_path
  end

  scenario 'Index shows budget investments assigned to current valuator' do
    investment1 = create(:budget_investment, budget: budget)
    investment2 = create(:budget_investment, budget: budget)

    investment1.valuators << valuator

    visit valuation_budget_budget_investments_path(budget)

    expect(page).to have_content(investment1.title)
    expect(page).not_to have_content(investment2.title)
  end

  scenario 'Index shows no budget investment to admins no valuators' do
    investment1 = create(:budget_investment, budget: budget)
    investment2 = create(:budget_investment, budget: budget)

    investment1.valuators << valuator

    logout
    login_as create(:administrator).user
    visit valuation_budget_budget_investments_path(budget)

    expect(page).not_to have_content(investment1.title)
    expect(page).not_to have_content(investment2.title)
  end

  scenario 'Index orders budget investments by votes' do
    investment10  = create(:budget_investment, budget: budget, cached_votes_up: 10)
    investment100 = create(:budget_investment, budget: budget, cached_votes_up: 100)
    investment1   = create(:budget_investment, budget: budget, cached_votes_up: 1)

    investment1.valuators << valuator
    investment10.valuators << valuator
    investment100.valuators << valuator

    visit valuation_budget_budget_investments_path(budget)

    expect(investment100.title).to appear_before(investment10.title)
    expect(investment10.title).to appear_before(investment1.title)
  end

  scenario "Index filtering by heading", :js do
    group = create(:budget_group, budget: budget)
    heading1 = create(:budget_heading, name: "District 9", group: group)
    heading2 = create(:budget_heading, name: "Down to the river", group: group)
    investment1 = create(:budget_investment, title: "Realocate visitors", heading: heading1,
                                             group: group, budget: budget)
    investment2 = create(:budget_investment, title: "Destroy the city", heading: heading2,
                                             group: group, budget: budget)
    investment1.valuators << valuator
    investment2.valuators << valuator

    visit valuation_budget_budget_investments_path(budget)

    expect(page).to have_link("Realocate visitors")
    expect(page).to have_link("Destroy the city")

    expect(page).to have_content "All headings (2)"
    expect(page).to have_content "District 9 (1)"
    expect(page).to have_content "Down to the river (1)"

    click_link "District 9", exact: false

    expect(page).to have_link("Realocate visitors")
    expect(page).not_to have_link("Destroy the city")

    click_link "Down to the river", exact: false

    expect(page).to have_link("Destroy the city")
    expect(page).not_to have_link("Realocate visitors")

    click_link "All headings", exact: false
    expect(page).to have_link("Realocate visitors")
    expect(page).to have_link("Destroy the city")
  end

  scenario "Current filter is properly highlighted" do
    filters_links = {'valuating' => 'Under valuation',
                     'valuation_finished' => 'Valuation finished'}

    visit valuation_budget_budget_investments_path(budget)

    expect(page).not_to have_link(filters_links.values.first)
    filters_links.keys.drop(1).each { |filter| expect(page).to have_link(filters_links[filter]) }

    filters_links.each_pair do |current_filter, link|
      visit valuation_budget_budget_investments_path(budget, filter: current_filter)

      expect(page).not_to have_link(link)

      (filters_links.keys - [current_filter]).each do |filter|
        expect(page).to have_link(filters_links[filter])
      end
    end
  end

  scenario "Index filtering by valuation status" do
    valuating = create(:budget_investment, budget: budget, title: "Ongoing valuation")
    valuated  = create(:budget_investment, budget: budget, title: "Old idea",
                                           valuation_finished: true)
    valuating.valuators << valuator
    valuated.valuators << valuator

    visit valuation_budget_budget_investments_path(budget)

    expect(page).to have_content("Ongoing valuation")
    expect(page).not_to have_content("Old idea")

    visit valuation_budget_budget_investments_path(budget, filter: 'valuating')

    expect(page).to have_content("Ongoing valuation")
    expect(page).not_to have_content("Old idea")

    visit valuation_budget_budget_investments_path(budget, filter: 'valuation_finished')

    expect(page).not_to have_content("Ongoing valuation")
    expect(page).to have_content("Old idea")
  end

  feature 'Show' do
    let(:administrator) do
      create(:administrator, user: create(:user, username: 'Ana', email: 'ana@admins.org'))
    end
    let(:second_valuator) do
      create(:valuator, user: create(:user, username: 'Rick', email: 'rick@valuators.org'))
    end
    let(:investment) do
      create(:budget_investment, budget: budget, price: 1234, feasibility: 'unfeasible',
                                 unfeasibility_explanation: 'It is impossible',
                                 administrator: administrator)
    end

    background do
      investment.valuators << [valuator, second_valuator]
    end

    scenario 'visible for assigned valuators' do
      visit valuation_budget_budget_investments_path(budget)

      click_link investment.title

      expect(page).to have_content(investment.title)
      expect(page).to have_content(investment.description)
      expect(page).to have_content(investment.author.name)
      expect(page).to have_content(investment.heading.name)
      expect(page).to have_content('1234')
      expect(page).to have_content('Unfeasible')
      expect(page).to have_content('It is impossible')
      expect(page).to have_content('Ana (ana@admins.org)')

      within('#assigned_valuators') do
        expect(page).to have_content('Rachel (rachel@valuators.org)')
        expect(page).to have_content('Rick (rick@valuators.org)')
      end
    end

    scenario 'visible for admins' do
      logout
      login_as create(:administrator).user

      visit valuation_budget_budget_investment_path(budget, investment)

      expect(page).to have_content(investment.title)
      expect(page).to have_content(investment.description)
      expect(page).to have_content(investment.author.name)
      expect(page).to have_content(investment.heading.name)
      expect(page).to have_content('1234')
      expect(page).to have_content('Unfeasible')
      expect(page).to have_content('It is impossible')
      expect(page).to have_content('Ana (ana@admins.org)')

      within('#assigned_valuators') do
        expect(page).to have_content('Rachel (rachel@valuators.org)')
        expect(page).to have_content('Rick (rick@valuators.org)')
      end
    end

    scenario 'not visible for not assigned valuators' do
      logout
      login_as create(:valuator).user

      expect{
        visit valuation_budget_budget_investment_path(budget, investment)
      }.to raise_error "Not Found"
    end

  end

  feature 'Valuate' do
    let(:admin) { create(:administrator) }
    let(:investment) do
      create(:budget_investment, budget: budget, price: nil,
                                                        administrator: admin)
    end

    background do
      investment.valuators << valuator
    end

    scenario 'Dossier empty by default' do
      visit valuation_budget_budget_investments_path(budget)
      click_link investment.title

      within('#price') { expect(page).to have_content('Undefined') }
      within('#price_first_year') { expect(page).to have_content('Undefined') }
      within('#duration') { expect(page).to have_content('Undefined') }
      within('#feasibility') { expect(page).to have_content('Undecided') }
      expect(page).not_to have_content('Valuation finished')
    end

    scenario 'Edit dossier' do
      visit valuation_budget_budget_investments_path(budget)
      within("#budget_investment_#{investment.id}") do
        click_link "Edit dossier"
      end

      fill_in 'budget_investment_price', with: '12345'
      fill_in 'budget_investment_price_first_year', with: '9876'
      fill_in 'budget_investment_price_explanation', with: 'Very cheap idea'
      choose  'budget_investment_feasibility_feasible'
      fill_in 'budget_investment_duration', with: '19 months'
      click_button 'Save changes'

      expect(page).to have_content "Dossier updated"

      visit valuation_budget_budget_investments_path(budget)
      click_link investment.title

      within('#price') { expect(page).to have_content('12345') }
      within('#price_first_year') { expect(page).to have_content('9876') }
      expect(page).to have_content('Very cheap idea')
      within('#duration') { expect(page).to have_content('19 months') }
      within('#feasibility') { expect(page).to have_content('Feasible') }
      expect(page).not_to have_content('Valuation finished')
    end

    scenario 'Feasibility can be marked as pending' do
      visit valuation_budget_budget_investment_path(budget, investment)
      click_link 'Edit dossier'

      expect(find("#budget_investment_feasibility_undecided")).to be_checked
      choose 'budget_investment_feasibility_feasible'
      click_button 'Save changes'

      visit edit_valuation_budget_budget_investment_path(budget, investment)

      expect(find("#budget_investment_feasibility_undecided")).not_to be_checked
      expect(find("#budget_investment_feasibility_feasible")).to be_checked

      choose 'budget_investment_feasibility_undecided'
      click_button 'Save changes'

      visit edit_valuation_budget_budget_investment_path(budget, investment)
      expect(find("#budget_investment_feasibility_undecided")).to be_checked
    end

    scenario 'Feasibility selection makes proper fields visible', :js do
      feasible_fields = ['Price (€)', 'Cost during the first year (€)', 'Price explanation',
                         'Time scope']
      unfeasible_fields = ['Feasibility explanation']
      any_feasibility_fields = ['Valuation finished']
      undecided_fields = feasible_fields + unfeasible_fields + any_feasibility_fields

      visit edit_valuation_budget_budget_investment_path(budget, investment)

      expect(find("#budget_investment_feasibility_undecided")).to be_checked

      undecided_fields.each do |field|
        expect(page).to have_content(field)
      end

      choose 'budget_investment_feasibility_feasible'

      unfeasible_fields.each do |field|
        expect(page).not_to have_content(field)
      end

      (feasible_fields + any_feasibility_fields).each do |field|
        expect(page).to have_content(field)
      end

      choose 'budget_investment_feasibility_unfeasible'

      feasible_fields.each do |field|
        expect(page).not_to have_content(field)
      end

      (unfeasible_fields + any_feasibility_fields).each do |field|
        expect(page).to have_content(field)
      end

      click_button 'Save changes'

      visit edit_valuation_budget_budget_investment_path(budget, investment)

      expect(find("#budget_investment_feasibility_unfeasible")).to be_checked
      feasible_fields.each do |field|
        expect(page).not_to have_content(field)
      end

      (unfeasible_fields + any_feasibility_fields).each do |field|
        expect(page).to have_content(field)
      end

      choose 'budget_investment_feasibility_undecided'

      undecided_fields.each do |field|
        expect(page).to have_content(field)
      end
    end

    scenario 'Finish valuation' do
      visit valuation_budget_budget_investment_path(budget, investment)
      click_link 'Edit dossier'

      find_field('budget_investment[valuation_finished]').click
      click_button 'Save changes'

      visit valuation_budget_budget_investments_path(budget)
      expect(page).not_to have_content investment.title
      click_link 'Valuation finished'

      expect(page).to have_content investment.title
      click_link investment.title
      expect(page).to have_content('Valuation finished')
    end

    context 'Reopen valuation' do
      background do
        investment.update(
          valuation_finished: true,
          feasibility: 'feasible',
          unfeasibility_explanation: 'Explanation is explanatory',
          price: 999,
          price_first_year: 666,
          price_explanation: 'Democracy is not cheap',
          duration: '1 light year'
        )
      end

      scenario 'Admins can reopen & modify finished valuation' do
        logout
        login_as(admin.user)
        visit edit_valuation_budget_budget_investment_path(budget, investment)

        expect(page).to have_selector("input[id='budget_investment_feasibility_undecided']")
        expect(page).to have_selector("textarea[id='budget_investment_unfeasibility_explanation']")
        expect(page).to have_selector("input[name='budget_investment[valuation_finished]']")
        expect(page).to have_button('Save changes')
      end

      scenario 'Valuators that are not admins cannot reopen or modify a finished valuation' do
        visit edit_valuation_budget_budget_investment_path(budget, investment)

        expect(page).not_to have_selector("input[id='budget_investment_feasibility_undecided']")
        expect(page).not_to have_selector("textarea[id='budget_investment_unfeasibility_explanation']")
        expect(page).not_to have_selector("input[name='budget_investment[valuation_finished]']")
        expect(page).to have_content('Valuation finished')
        expect(page).to have_content('Feasibility: Feasible')
        expect(page).to have_content('Feasibility explanation: Explanation is explanatory')
        expect(page).to have_content('Price (€): 999')
        expect(page).to have_content('Cost during the first year: 666')
        expect(page).to have_content('Price explanation: Democracy is not cheap')
        expect(page).to have_content('Time scope: 1 light year')
        expect(page).not_to have_button('Save changes')
      end
    end

    scenario 'Validates price formats' do
      visit valuation_budget_budget_investments_path(budget)
      within("#budget_investment_#{investment.id}") do
        click_link "Edit dossier"
      end

      fill_in 'budget_investment_price', with: '12345,98'
      fill_in 'budget_investment_price_first_year', with: '9876.6'
      click_button 'Save changes'

      expect(page).to have_content('2 errors')
      expect(page).to have_content('Only integer numbers', count: 2)
    end
  end
end
