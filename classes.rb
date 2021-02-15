class DeliveryCondition < ApplicationRecord
  # fields: delivery_description, delivery_description_en, min_days, max_days
  has_many :products, dependent: :restrict_with_exception
  has_many :articles, dependent: :restrict_with_exception

  belongs_to :country

  include TranslationService

  default_scope { order('rank DESC NULLS LAST') }

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  has_paper_trail
end

class Product < ApplicationRecord
  belongs_to :article
  belongs_to :delivery_condition 

  # I propably don't have enough domain knowledge 
  # This comments are only for clarifying my solution
  #  I made some assumptions:
  # 1. By 'defined' I assume active flag set to true was meant -> because no optional: true is set 
  # on the associations in article and product model + what is a purpose of belongs_to association
  # 2. I think there is a gross redundancy of data causing problems
  def delivery_description(country_code)
    # error(exception) handlig by convetion on the higher level of abstraction (reason I use ! methods)
    # to fetch once - performance/define vars at the beginning on the method
    # I assume there is a one-to-many-relation between the Country and the DeliveryCondition
    # and each country has the record in countries table + there is a name column there
    country_delivery_cond = Country.find_by!(name: country_code).delivery_conditions 
    country_product_cond = country_delivery_cond.find_first { |el| el.products.include?(self) }
    country_article_cond = country_delivery_cond.find_first { |el| el.articles.include?(self.article) }
    is_article_cond = country_article_cond.active? # var names can't have ? sufix
    is_product_cond = country_product_cond.active?

    if is_article_cond && is_product_cond
      return build_delivery_description(product_delivery)
    elsif is_article_cond
      return build_delivery_description(article_delivery)
    elsif is_product_cond
      return build_delivery_description(product_delivery)
    end

    raise Error, 'No data for given country' # I18n should be used
  end

  private 

  # I assume this is a concat of the I18n str from delivery_condition record 
  # and the sufix from the task
  def build_delivery_description(delivery_condition)
    # here we can use Rails defaul I18n 
    # in e.g format for en.yml from %{min_days} to %{max_days}
    sufix_delivery_desc = I18n.t('delivery.condition.description.sufx', min_days: delivery_condition.min_days, max_days: delivery_condition.max_days)
    basic_string = delivery_condition.operate_i18n(:delivery_description)
    basic_string + ' ' + sufix_delivery_desc
  end
end

class Article < ApplicationRecord
  has_many    :products
  belongs_to  :delivery_condition
end

module TranslationService
  extend ActiveSupport::Concern

  # We assume that a field to translate is german "subject" and english "subject_en"
  def operate_i18n(model_column, options = {})
    found_column = model_column.to_s
    english_translation_field = "#{found_column}_en"

    language_to_compare = I18n.locale.to_s
    language_to_compare = options[:find_locale] if options[:find_locale].present?

    if language_to_compare == 'de'
      return nil if self[found_column].blank?
      self[found_column].to_s.html_safe
    elsif language_to_compare == 'en' && !self[english_translation_field].blank?
      self[english_translation_field].to_s.html_safe
    else
      return nil if self[found_column].blank?
      self[found_column].to_s.html_safe
    end
  end
end
