require "json_locale/version"

module JsonLocale
  module Translates

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end

    module ClassMethods

      # adds convinience methods used for managing translations on a json type attribute
      # The translated attribute must be have the suffix '_translations
      # Example:
      # class SomeClass
      #   include JsonLocale::Translates
      #   translates :name, {}
      # end
      # 
      # Available instance methods:
      # - instance.name
      # - instance.name_en
      # - instance.set_title_en('Some Name', {})
      # - instance.set_title_translations({en: 'Some Name'}, {})
      # Available class methods:
      # - SomeClass.translates?
      # - translates
      # - translatable_attributes

      def translates(attr_name, suffix: '_translations', allow_blank: false, fallback: false)
        normalized_attr_name = attr_name.to_s.sub(suffix, '').to_sym
        I18n.available_locales.each do |locale|
          normalized_locale = locale.to_s.downcase.gsub(/[^a-z]/, '')

          # instance.title
          # @param params.locale The locale to be used
          # return The translated value for the current locale (I18n.locale)
          define_method :"#{normalized_attr_name}" do |**params|
            read_json_translation(
              attr_name,
              locale: params.fetch(:locale, I18n.locale),
              fallback: params.fetch(:fallback, fallback)
            )
          end

          define_method :"#{normalized_attr_name}_#{normalized_locale}" do |**params|
            read_json_translation(
              attr_name,
              locale: normalized_locale,
              fallback: params.fetch(:fallback, fallback)
            )
          end

          define_method "set_#{normalized_attr_name}_#{normalized_locale}" do |value, **params|
            write_json_translation(
              attr_name,
              value,
              locale: normalized_locale,
              allow_blank: params.fetch(:allow_blank, allow_blank)
            )
          end

        end

      end

      # return [Boolean] true if the class has translatable attributes
      def translates?
        included_modules.include?(InstanceMethods)
      end

      # def translatable_attributes
      # end

    end

    module InstanceMethods

      private

      def write_json_translation(attr_name, value, locale:, allow_blank:)
        locale = locale.to_s
        value = allow_blank ? value : value.presence
        translations = public_send(attr_name) || {}
        public_send("#{attr_name}_will_change!") unless translations[locale] == value
        if value
          translations[locale] = value
        else
          translations.delete(locale)
        end
        public_send("#{attr_name}=", translations)
        value
      end

      def read_json_translation(attr_name, locale:, fallback:)
        locale = locale.to_s
        translations = public_send(attr_name) || {}

        value = if translations.key?(locale)
          translations[locale]
        else
          case fallback
          when :any
            translations.find{|k,v| !v.nil?}.try(:[], 1)
          when :i18n
            # ToDo
          when Array
            fallback.find{|locale| !translations[locale].nil?}.try(:[], 1)
          else
            nil
          end
        end

        value
      end

      # def json_translate_fallback_locales(locale)
      #   if enabled_fallback != false && I18n.respond_to?(:fallbacks)
      #     Array(I18n.fallbacks[locale])
      #   else
      #     Array(locale)
      #   end
      # end

    end

  end
end
