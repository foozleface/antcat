require 'rails_helper'

describe UnknownReference do
  describe 'validations' do
    it { is_expected.to validate_presence_of :year }
    it { is_expected.to validate_presence_of :citation }
  end
end
