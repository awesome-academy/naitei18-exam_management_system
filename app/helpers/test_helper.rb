module TestHelper
  def set_time
    @remaining_time = Time.at(@test.subject.test_duration * 60)
                          .utc.strftime("%H:%M:%S")
  end

  def set_end_time
    @end_time = Time.now.to_i + @test.subject.test_duration * 60
  end

  def variable_question_partial question
    return question if @test.doing?

    question&.question
  end

  def set_method_fields_for question
    return :id if @test.doing?

    return :first_answer_id if question.single_choice?

    :answer_ids
  end

  def check_disable
    return {disabled: false} if @test.doing?

    {disabled: :set_disabled}
  end

  def set_status test
    return t "tests.index.in_progress" if test.doing?

    return t "tests.index.passed" if test.passed?

    t "tests.index.failed"
  end

  def completed_tests tests
    tests.completed
  end

  def progressing_tests tests
    tests.progressing
  end
end
