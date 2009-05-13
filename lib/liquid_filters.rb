module LiquidFilters

  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper  

  def currency(price)
    number_to_currency(price)
  end
  
  def mailto(email)
    mail_to(email,email,:encode => "javascript")
  end

  def possessive(name)
    name.possessive
  end
  
end


