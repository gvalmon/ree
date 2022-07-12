# frozen_string_literal: true

class ReeValidator::ValidateLength
  include Ree::FnDSL

  fn :validate_length do
    link :t, from: :ree_i18n
  end

  LenthErr = Class.new(StandardError)

  contract(
    -> { _1.respond_to?(:length) },
    Nilor[SubclassOf[StandardError]],
    Ksplat[
      min?: Integer,
      max?: Integer,
      equal_to?: Integer,
      not_equal_to?: Integer,
    ] => Bool
    ).throws(LenthErr)
  def call(object, error = nil, **opts)
    min, max, equal_to, not_equal_to = opts.values_at(:min, :max, :equal_to, :not_equal_to)
    klass = error || LenthErr

    if min && object.length < min
      raise klass.new(
        t(
          'validator.length.can_not_be_less_than',
          {length: min},
          default_by_locale: :en
        )
      )
    end

    if max && object.length > max
      raise klass.new(
        t(
          'validator.length.can_not_be_more_than',
          {length: max},
          default_by_locale: :en
        )
      )
    end

    if equal_to && object.length != equal_to
      raise klass.new(
        t(
          'validator.length.should_be_equal_to',
          {length: equal_to},
          default_by_locale: :en
        )
      )
    end

    if not_equal_to && object.length == not_equal_to
      raise klass.new(
        t(
          'validator.length.should_not_be_equal_to',
          {length: not_equal_to},
          default_by_locale: :en
        )
      )
    end

    true
  end
end