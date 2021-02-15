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

  def delivery_description(country_code)
    # assuming name column in the countries table + because of the usage of a paper trail gem
    country_delivery_newest_cond = Country.find_by!(name: country_name).delivery_conditions.versions.last

    # format of the example de.yml string delivery description %{down_boundary} bis %{upper_boundary} Tage
    I18n.t('product.delivery', down_boundary: x_days, upper_boundary: y_days)
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
