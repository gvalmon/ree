# frozen_string_literal: true

require 'date'
require 'tzinfo'

module ReeDatetime
  include Ree::PackageDSL

  package do
    depends_on :ree_date
    depends_on :ree_hash
    depends_on :ree_number
    depends_on :ree_i18n
  end
end

package_require('ree_i18n/functions/add_load_path')

add_load_path = ReeI18n::AddLoadPath.new
add_load_path.(Dir[File.join(__dir__, 'ree_datetime/locales/*.yml')])